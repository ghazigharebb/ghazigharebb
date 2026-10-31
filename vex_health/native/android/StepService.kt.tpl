package __PKG__

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import java.util.Calendar
import java.util.Locale
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * VEX Health — خزمەتگوزاری هەنگاو (Foreground Service)
 *  - هەنگاوەکان لە سێنسەری مۆبایل (TYPE_STEP_COUNTER) دەژمێرێت، تەنانەت ئەگەر ئەپەکە داخرابێت
 *  - ئەگەر Flutter داتای Band ـی نارد، لەسەر ئەو بنەما دەمێنێتەوە و هەنگاوی مۆبایل لەسەری زیاد دەکات
 *  - ئەگەر notification ـەکە بسڕدرێتەوە (swipe)، دوای 1 خولەک خۆی دەگەڕێتەوە
 */
class StepService : Service(), SensorEventListener {

    companion object {
        const val CH_ID = "vex_steps"
        const val NOTIF_ID = 7101
        const val PREFS = "vex_steps_prefs"
        const val REPOST_MS = 60_000L
        const val TICK_MS = 60_000L
        const val MIN_REFRESH_MS = 3_000L

        @Volatile var inst: StepService? = null

        fun prefs(c: Context): SharedPreferences = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun today(): String {
            val c = Calendar.getInstance()
            return "${c.get(Calendar.YEAR)}-${c.get(Calendar.MONTH) + 1}-${c.get(Calendar.DAY_OF_MONTH)}"
        }
    }

    private val main = Handler(Looper.getMainLooper())
    private lateinit var sp: SharedPreferences
    private var sensorOn = false
    private var dismissed = false
    private var started = false
    private var lastPost = 0L

    private val repost = Runnable { dismissed = false; refresh(true) }
    private val tick = object : Runnable {
        override fun run() {
            rollDayIfNeeded()
            refresh(true)
            main.postDelayed(this, TICK_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        sp = prefs(this)
        inst = this
        ensureChannel()
    }

    override fun onBind(i: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "vex.STOP") {
            shutdown()
            return START_NOT_STICKY
        }
        // دوای کوژانەوەی سیستەم (intent = null) تەنها ئەگەر بەکارهێنەر کردبێتیەوە دەمێنێتەوە
        if (!sp.getBoolean("enabled", false)) {
            // startForegroundService() دەبێت startForeground() ـیش بانگ بکرێت، ئەگینا سیستەم ئەپەکە دەکوژێت
            if (!started) {
                try { startForeground(NOTIF_ID, build()) } catch (_: Exception) {}
            }
            shutdown()
            return START_NOT_STICKY
        }
        if (!started) {
            started = true
            val n = build()
            try {
                if (Build.VERSION.SDK_INT >= 30) {
                    startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
                } else {
                    startForeground(NOTIF_ID, n)
                }
            } catch (e: Exception) {
                // مۆڵەتی چالاکی جەستەیی نەماوە یان سیستەم ڕێگای نەدا
                sp.edit().putBoolean("enabled", false).apply()
                started = false
                stopSelf()
                return START_NOT_STICKY
            }
            startSensor()
            main.removeCallbacks(tick)
            main.postDelayed(tick, TICK_MS)
        } else {
            refresh(true)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        main.removeCallbacksAndMessages(null)
        stopSensor()
        if (inst === this) inst = null
        super.onDestroy()
    }

    private fun shutdown() {
        main.removeCallbacksAndMessages(null)
        stopSensor()
        started = false
        try {
            if (Build.VERSION.SDK_INT >= 24) stopForeground(STOP_FOREGROUND_REMOVE) else @Suppress("DEPRECATION") stopForeground(true)
        } catch (_: Exception) {}
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTIF_ID)
        stopSelf()
    }

    // ---------- سێنسەر ----------
    private fun startSensor() {
        if (sensorOn) return
        val sm = getSystemService(SENSOR_SERVICE) as SensorManager
        val s = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) ?: return
        sensorOn = try {
            sm.registerListener(this, s, SensorManager.SENSOR_DELAY_NORMAL, 5_000_000)
        } catch (_: Exception) { false }
    }

    private fun stopSensor() {
        if (!sensorOn) return
        try { (getSystemService(SENSOR_SERVICE) as SensorManager).unregisterListener(this) } catch (_: Exception) {}
        sensorOn = false
    }

    override fun onAccuracyChanged(s: Sensor?, a: Int) {}

    override fun onSensorChanged(e: SensorEvent) {
        if (e.values.isEmpty()) return
        val raw = e.values[0].toLong()
        rollDayIfNeeded()
        val last = sp.getLong("lastRaw", -1L)
        // دوای ڕیستارتی مۆبایل سێنسەرەکە لە سفرەوە دەست پێدەکاتەوە
        val delta = if (last < 0) 0L else if (raw >= last) raw - last else raw
        sp.edit()
            .putLong("lastRaw", raw)
            .putLong("phoneToday", sp.getLong("phoneToday", 0L) + delta)
            .apply()
        refresh(false)
    }

    private fun rollDayIfNeeded() {
        val t = today()
        if (sp.getString("day", "") != t) {
            sp.edit().putString("day", t).putLong("phoneToday", 0L).apply()
        }
    }

    // ---------- هەنگاوی ئێستا ----------
    private fun currentSteps(): Int {
        val phone = sp.getLong("phoneToday", 0L)
        val sameDay = sp.getString("pushDay", "") == today()
        if (!sameDay) return max(0L, phone).toInt()
        val base = sp.getLong("pushSteps", 0L)
        val since = max(0L, phone - sp.getLong("pushPhone", 0L))
        return (base + since).toInt()
    }

    /** لە Flutter ـەوە (Band) داتای نوێ هات */
    fun onPush() {
        rollDayIfNeeded()
        sp.edit().putLong("pushPhone", sp.getLong("phoneToday", 0L)).apply()
        refresh(true)
    }

    fun onDismissed() {
        dismissed = true
        main.removeCallbacks(repost)
        main.postDelayed(repost, REPOST_MS)
    }

    private val pending = Runnable { refresh(true) }

    fun refresh(force: Boolean) {
        if (!started || dismissed) return
        val now = System.currentTimeMillis()
        if (!force && now - lastPost < MIN_REFRESH_MS) {
            // زۆر زوو هاتووە: دوای ماوەی ماوە یەک جار نوێ دەکرێتەوە (هیچ هەنگاوێک ون نابێت)
            main.removeCallbacks(pending)
            main.postDelayed(pending, MIN_REFRESH_MS - (now - lastPost))
            return
        }
        main.removeCallbacks(pending)
        lastPost = now
        try {
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(NOTIF_ID, build())
        } catch (_: Exception) {}
    }

    // ---------- notification ----------
    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CH_ID) != null) return
        val ch = NotificationChannel(CH_ID, "هەنگاوەکان", NotificationManager.IMPORTANCE_LOW)
        ch.description = "هەنگاو، کالۆری و ماوەی ئامانجی ڕۆژانە"
        ch.setShowBadge(false)
        ch.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        nm.createNotificationChannel(ch)
    }

    private fun fmt(n: Int): String = String.format(Locale.US, "%,d", n)

    private fun build(): Notification {
        val steps = currentSteps()
        val goal = max(1, sp.getInt("goal", 10000))
        val hCm = sp.getInt("heightCm", 170).coerceIn(100, 250)
        val wKg = sp.getInt("weightKg", 70).coerceIn(25, 250)
        val hr = sp.getInt("hr", 0)
        val stride = 0.415 * hCm / 100.0
        val km = steps * stride / 1000.0
        val kcal = km * wKg * 0.63
        val rem = max(0, goal - steps)
        val remKm = rem * stride / 1000.0
        val remMin = ceil(rem / 105.0).toInt()
        val pct = min(100, (steps * 100L / goal).toInt())
        val done = rem == 0

        val dark = StepArt.isDark(this)
        val tx = if (dark) 0xFFFFFFFF.toInt() else 0xFF0B1F26.toInt()
        val mu = if (dark) 0xFF9FB7BD.toInt() else 0xFF4D6B73.toInt()
        val f1 = String.format(Locale.US, "%.1f", remKm)
        val f2 = String.format(Locale.US, "%.2f", km)
        val pctTxt = "$pct%"
        val remTxt = if (done) "ئامانجی ئەمڕۆ تەواو بوو" else "ماوە ${fmt(rem)}"
        val heroS = StepArt.hero(this, steps, goal, 24f, dark, done)
        val heroB = StepArt.hero(this, steps, goal, 40f, dark, done)
        val p = StepArt.pct(steps, goal)

        // کورتکراوە
        val small = RemoteViews(packageName, R.layout.vex_notif_small)
        small.setImageViewBitmap(R.id.imHero, heroS)
        small.setTextColor(R.id.tvUnit, mu)
        small.setTextViewText(R.id.tvPct, pctTxt)
        small.setTextColor(R.id.tvPct, if (done) 0xFF3CF08A.toInt() else 0xFF2FE6F3.toInt())
        small.setImageViewBitmap(R.id.imTrack, StepArt.track(this, p, done, false, dark, goal))

        // کراوە
        val big = RemoteViews(packageName, R.layout.vex_notif_big)
        big.setTextColor(R.id.tvHead, mu)
        big.setTextViewText(R.id.tvHead, if (done) "گەشتی ئەمڕۆ تەواو بوو" else "گەشتی ئەمڕۆ بۆ ئامانج")
        big.setImageViewBitmap(R.id.imHero, heroB)
        big.setTextViewText(R.id.tvPct, pctTxt)
        big.setTextColor(R.id.tvPct, if (done) 0xFF3CF08A.toInt() else 0xFF2FE6F3.toInt())
        big.setImageViewBitmap(R.id.imTrack, StepArt.track(this, p, done, true, dark, goal))
        big.setTextViewText(R.id.tvRem, remTxt)
        big.setTextViewText(R.id.tvRemKm, "$f1 کم")
        big.setTextViewText(R.id.tvRemMin, "$remMin خولەک")
        big.setViewVisibility(R.id.tvRemKm, if (done) android.view.View.GONE else android.view.View.VISIBLE)
        big.setViewVisibility(R.id.tvRemMin, if (done) android.view.View.GONE else android.view.View.VISIBLE)
        big.setTextViewText(R.id.tvKm, "$f2 کم")
        big.setTextViewText(R.id.tvKcal, "${kcal.toInt()} kcal")
        big.setTextViewText(R.id.tvHr, if (hr in 30..220) "$hr bpm" else "")
        big.setViewVisibility(R.id.tvHr, if (hr in 30..220) android.view.View.VISIBLE else android.view.View.GONE)
        for (id in intArrayOf(R.id.tvKm, R.id.tvKcal, R.id.tvHr)) big.setTextColor(id, tx)
        if (!dark) {
            // لە دۆخی ڕووناکدا ڕەنگی تۆختر بۆ خوێندنەوە لەسەر کارتی سپی
            big.setTextColor(R.id.tvRem, 0xFF0A7F8A.toInt())
            big.setTextColor(R.id.tvRemKm, 0xFF1F6FA3.toInt())
            big.setTextColor(R.id.tvRemMin, 0xFF5A48B8.toInt())
        }
        val sub = if (done) remTxt else "$remTxt هەنگاو · $f1 کم · نزیکەی $remMin خولەک"

        val imm = if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or imm)
        }
        val water = PendingIntent.getBroadcast(
            this, 2, Intent(this, StepReceiver::class.java).setAction("vex.WATER"),
            PendingIntent.FLAG_UPDATE_CURRENT or imm
        )
        val del = PendingIntent.getBroadcast(
            this, 1, Intent(this, StepReceiver::class.java).setAction("vex.DISMISSED"),
            PendingIntent.FLAG_UPDATE_CURRENT or imm
        )

        val b = NotificationCompat.Builder(this, CH_ID)
            .setSmallIcon(R.drawable.ic_stat_vx)
            .setContentTitle("${fmt(steps)} هەنگاو · $pct%")
            .setContentText(sub)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(small)
            .setCustomBigContentView(big)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setColor(0xFF2FE6F3.toInt())
            .setDeleteIntent(del)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .addAction(R.drawable.ic_stat_vx, "ئاو +١", water)
        if (open != null) {
            b.setContentIntent(open)
            b.addAction(R.drawable.ic_stat_vx, "کردنەوە", open)
        }
        return b.build()
    }
}
