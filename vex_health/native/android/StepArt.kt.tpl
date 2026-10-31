package __PKG__

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import androidx.core.content.ContextCompat
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * VEX — وێنەکانی ئاگادارکردنەوەی هەنگاو (دیزاینی «گەشت»)
 *  - hero():  ژمارەی هەنگاو بە فۆنتی Sora (هەمان فۆنتی ئەپ) + « / 10,000»
 *  - track(): ڕێگای گەشت: ماڵ ← ڕاکەر ← ئاڵا، خاڵەکانی 2.5k / 5k / 7.5k، پێوەرەکە
 * RemoteViews فۆنتی تایبەت و کێشانی ئازاد قبوڵ ناکات، بۆیە ئەم دوو بەشە وەک وێنە دەکێشرێن.
 */
object StepArt {
    private const val CY = 0xFF2FE6F3.toInt()
    private const val MINT = 0xFF3CF08A.toInt()

    private var sora: Typeface? = null
    private var soraMed: Typeface? = null

    private fun dp(c: Context, v: Float): Float = v * c.resources.displayMetrics.density

    fun isDark(c: Context): Boolean =
        (c.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    private fun font(c: Context, bold: Boolean): Typeface {
        if (bold && sora != null) return sora!!
        if (!bold && soraMed != null) return soraMed!!
        val name = if (bold) "Sora-ExtraBold.ttf" else "Sora-Medium.ttf"
        val t = try {
            Typeface.createFromAsset(c.assets, "flutter_assets/assets/google_fonts/$name")
        } catch (_: Exception) {
            if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
        if (bold) sora = t else soraMed = t
        return t
    }

    private fun fmt(n: Int): String = String.format(java.util.Locale.US, "%,d", n)

    /** پانیی ناوەڕۆکی notification (نزیکەی): شاشە − ئایکۆنی ئەپ − بۆشاییەکان */
    fun contentWidth(c: Context): Int {
        val w = c.resources.displayMetrics.widthPixels
        return min((w - dp(c, 128f)).roundToInt(), dp(c, 330f).roundToInt())
    }

    /** «1,456 / 10,000» — بەرزی بە dp. لە ڕۆژی تەواوبوون ژمارەکە سەوزە. */
    fun hero(c: Context, steps: Int, goal: Int, heightDp: Float, dark: Boolean, done: Boolean): Bitmap {
        val h = dp(c, heightDp)
        val big = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = font(c, true)
            textSize = h * 0.78f
            color = if (done) MINT else (if (dark) Color.WHITE else 0xFF0B1F26.toInt())
            letterSpacing = -0.02f
        }
        val small = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = font(c, false)
            textSize = h * 0.34f
            color = if (dark) 0xFF9FB7BD.toInt() else 0xFF4D6B73.toInt()
        }
        val a = fmt(steps)
        val b = " / ${fmt(goal)}"
        val wa = big.measureText(a)
        val wb = small.measureText(b)
        val w = (wa + wb + dp(c, 2f)).roundToInt().coerceAtLeast(1)
        val bmp = Bitmap.createBitmap(w, h.roundToInt(), Bitmap.Config.ARGB_8888)
        val cv = Canvas(bmp)
        val base = h * 0.76f
        cv.drawText(a, 0f, base, big)
        cv.drawText(b, wa + dp(c, 2f), base, small)
        return bmp
    }

    /**
     * ڕێگای گەشت. [pct] 0..1، لە ڕاستەوە (ماڵ) بەرەو چەپ (ئاڵا).
     * [scale] = پێوەری 0 · 2.5k · 5k · 7.5k · 10k لە ژێرەوە (تەنها لە شێوەی کراوەدا).
     */
    fun track(c: Context, pct: Float, done: Boolean, scale: Boolean, dark: Boolean, goal: Int): Bitmap {
        val w = contentWidth(c)
        val trackH = dp(c, 34f)
        val h = (trackH + if (scale) dp(c, 18f) else 0f).roundToInt()
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val cv = Canvas(bmp)
        val cy = trackH / 2f
        val end = dp(c, 12f)            // تەوەرەی بازنەی ماڵ / ئاڵا
        val xHome = w - end
        val xFlag = end
        val l = xFlag + dp(c, 12f)      // کۆتایی چەپی هێڵ
        val r = xHome - dp(c, 12f)      // کۆتایی ڕاستی هێڵ
        val p = pct.coerceIn(0f, 1f)
        val xRun = if (done) xFlag else r - (r - l) * p   // لە تەواوبووندا ڕێک لەسەر ئاڵاکە

        val card = if (dark) 0xFF13262C.toInt() else Color.WHITE
        val line = if (dark) 0x38FFFFFF else 0x33000000
        val msFill = if (dark) 0xFF18323A.toInt() else 0xFFE3EEF1.toInt()
        val msRing = if (dark) 0x38FFFFFF else 0x2E000000

        // هێڵی خاڵخاڵ
        val dash = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = line; style = Paint.Style.STROKE; strokeWidth = dp(c, 2f)
            pathEffect = DashPathEffect(floatArrayOf(dp(c, 4f), dp(c, 3f)), 0f)
        }
        cv.drawLine(l, cy, r, cy, dash)

        // هێڵی تەواوبوو (لەگەڵ گڵۆپ)
        if (p > 0f) {
            val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(xRun, 0f, r, 0f, MINT, CY, Shader.TileMode.CLAMP)
                setShadowLayer(dp(c, 6f), 0f, 0f, 0x663CF08A)
            }
            val t = dp(c, 2f)
            cv.drawRoundRect(RectF(xRun, cy - t, r, cy + t), t, t, fill)
        }

        // خاڵەکانی 25 / 50 / 75
        for (m in intArrayOf(25, 50, 75)) {
            val x = r - (r - l) * m / 100f
            val passed = p * 100f >= m
            val rad = dp(c, if (passed) 5f else 4f)
            val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (passed) 0x4D3CF08A else msRing; style = Paint.Style.STROKE; strokeWidth = dp(c, 2f)
            }
            cv.drawCircle(x, cy, rad + dp(c, 1f), ring)
            cv.drawCircle(x, cy, rad, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = if (passed) MINT else msFill })
        }

        // ماڵ (ڕاست)
        cv.drawCircle(xHome, cy, dp(c, 12f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = if (dark) 0xFF1D363E.toInt() else 0xFFDCE9ED.toInt() })
        icon(c, cv, R.drawable.ic_vx_home, xHome, cy, dp(c, 13f), if (dark) 0xFF9FC3CB.toInt() else 0xFF4D6B73.toInt(), false)

        // ئاڵا (چەپ) — تا نەگەیشتوویە
        if (!done) {
            cv.drawCircle(xFlag, cy, dp(c, 12f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x293CF08A })
            cv.drawCircle(xFlag, cy, dp(c, 11.5f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x593CF08A; style = Paint.Style.STROKE; strokeWidth = dp(c, 1f) })
            icon(c, cv, R.drawable.ic_vx_flag, xFlag, cy, dp(c, 13f), MINT, true)
        }

        // ڕاکەر: هاڵۆ + بازنەی گرادیەنت + کەسی پیادە (لە تەواوبووندا: ئاڵای چەقاو + ✓)
        val glow = if (done) 0x663CF08A else 0x592FE6F3
        val halo = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(xRun, cy, dp(c, 19f), intArrayOf(glow, 0x002FE6F3), floatArrayOf(0f, 0.7f), Shader.TileMode.CLAMP)
        }
        cv.drawCircle(xRun, cy, dp(c, 19f), halo)
        cv.drawCircle(xRun, cy, dp(c, 15.5f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = card })
        val ball = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = if (done)
                LinearGradient(xRun - dp(c, 13f), cy - dp(c, 13f), xRun + dp(c, 13f), cy + dp(c, 13f), MINT, 0xFF19C46A.toInt(), Shader.TileMode.CLAMP)
            else
                LinearGradient(xRun - dp(c, 13f), cy - dp(c, 13f), xRun + dp(c, 13f), cy + dp(c, 13f), CY, MINT, Shader.TileMode.CLAMP)
            setShadowLayer(dp(c, 8f), 0f, dp(c, 3f), if (done) 0x803CF08A.toInt() else 0x732FE6F3)
        }
        cv.drawCircle(xRun, cy, dp(c, 13f), ball)
        if (done) {
            icon(c, cv, R.drawable.ic_vx_flag, xRun, cy, dp(c, 14f), 0xFF04323A.toInt(), false)
            // نیشانەی ✓ لە سەرەوە
            val bx = xRun + dp(c, 11f); val by = cy - dp(c, 11f)
            cv.drawCircle(bx, by, dp(c, 8f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = card })
            cv.drawCircle(bx, by, dp(c, 6.5f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE })
            val ck = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFF0B7A3E.toInt(); style = Paint.Style.STROKE; strokeWidth = dp(c, 1.8f)
                strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND
            }
            val path = android.graphics.Path().apply {
                moveTo(bx - dp(c, 3.2f), by + dp(c, 0.2f)); lineTo(bx - dp(c, 0.8f), by + dp(c, 2.6f)); lineTo(bx + dp(c, 3.4f), by - dp(c, 2.4f))
            }
            cv.drawPath(path, ck)
        } else {
            icon(c, cv, R.drawable.ic_vx_walk, xRun, cy, dp(c, 15f), 0xFF04323A.toInt(), true)
        }

        // پێوەر
        if (scale) {
            val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = font(c, false); textSize = dp(c, 10f)
                color = if (dark) 0xFF8FB3BB.toInt() else 0xFF5A7880.toInt()
            }
            val y = trackH + dp(c, 13f)
            val k = goal / 1000f
            val labels = listOf("0", short(k * .25f), short(k * .5f), short(k * .75f), short(k))
            for ((i, s) in labels.withIndex()) {
                val x = r - (r - l) * i / 4f
                tp.textAlign = when (i) { 0 -> Paint.Align.RIGHT; 4 -> Paint.Align.LEFT; else -> Paint.Align.CENTER }
                cv.drawText(s, x, y, tp)
            }
        }
        return bmp
    }

    private fun short(k: Float): String =
        if (k == k.roundToInt().toFloat()) "${k.roundToInt()}k" else String.format(java.util.Locale.US, "%.1fk", k)

    private fun icon(c: Context, cv: Canvas, res: Int, x: Float, y: Float, size: Float, tint: Int, flip: Boolean) {
        val d = ContextCompat.getDrawable(c, res)?.mutate() ?: return
        d.setTint(tint)
        val s = size / 2f
        d.setBounds((x - s).roundToInt(), (y - s).roundToInt(), (x + s).roundToInt(), (y + s).roundToInt())
        cv.save()
        if (flip) cv.scale(-1f, 1f, x, y)
        d.draw(cv)
        cv.restore()
    }

    /** پێشکەوتن وەک 0..1 */
    fun pct(steps: Int, goal: Int): Float = (steps.toFloat() / max(1, goal)).coerceIn(0f, 1f)
}
