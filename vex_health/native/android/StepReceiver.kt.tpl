package __PKG__

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/** swipe ـی notification، دوگمەی ئاو، و دەستپێکردنەوە دوای ڕیستارتی مۆبایل */
class StepReceiver : BroadcastReceiver() {
    override fun onReceive(c: Context, i: Intent) {
        when (i.action) {
            "vex.DISMISSED" -> StepService.inst?.onDismissed()
            "vex.WATER" -> {
                val sp = StepService.prefs(c)
                sp.edit().putInt("water", sp.getInt("water", 0) + 1).apply()
            }
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                if (StepService.prefs(c).getBoolean("enabled", false)) {
                    try {
                        ContextCompat.startForegroundService(c, Intent(c, StepService::class.java))
                    } catch (_: Exception) {}
                }
            }
        }
    }
}
