package __PKG__

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** پردی Flutter ↔ StepService (کەناڵی vex/steps) */
object StepsChannel {
    fun register(m: BinaryMessenger, ctx: Context) {
        MethodChannel(m, "vex/steps").setMethodCallHandler { call, result ->
            try {
                handle(ctx, call, result)
            } catch (e: Exception) {
                result.error("native", e.message, null)
            }
        }
    }

    private fun save(ctx: Context, call: MethodCall) {
        val e = StepService.prefs(ctx).edit()
        fun int(k: String): Int? = (call.argument<Number>(k))?.toInt()
        int("steps")?.let {
            e.putLong("pushSteps", it.toLong())
            e.putString("pushDay", call.argument<String>("day") ?: StepService.today())
        }
        int("goal")?.let { e.putInt("goal", it) }
        int("heightCm")?.let { e.putInt("heightCm", it) }
        int("weightKg")?.let { e.putInt("weightKg", it) }
        int("hr")?.let { e.putInt("hr", it) }
        e.apply()
    }

    private fun handle(ctx: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                save(ctx, call)
                val sp = StepService.prefs(ctx)
                sp.edit().putBoolean("enabled", true).apply()
                val s = StepService.inst
                if (s != null) {
                    s.onPush()
                } else {
                    // خزمەتگوزارییەکە هێشتا نەکراوەتەوە: هەنگاوی مۆبایل لە ئێستاوە لەسەر داتای Band زیاد دەبێت
                    sp.edit().putLong("pushPhone", sp.getLong("phoneToday", 0L)).apply()
                    ContextCompat.startForegroundService(ctx, Intent(ctx, StepService::class.java))
                }
                result.success(true)
            }
            "update" -> {
                save(ctx, call)
                StepService.inst?.onPush()
                result.success(true)
            }
            "stop" -> {
                StepService.prefs(ctx).edit().putBoolean("enabled", false).apply()
                val s = StepService.inst
                if (s != null) ctx.startService(Intent(ctx, StepService::class.java).setAction("vex.STOP"))
                result.success(true)
            }
            "takeWater" -> {
                val sp = StepService.prefs(ctx)
                val n = sp.getInt("water", 0)
                if (n > 0) sp.edit().putInt("water", 0).apply()
                result.success(n)
            }
            else -> result.notImplemented()
        }
    }
}
