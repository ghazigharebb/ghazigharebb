# شاشەی LED ـی وەستا غەریب — 720×200، 10 چرکە

| فایل | بۆچی |
|---|---|
| `wastaghareb_led_720x200.mp4` | ڤیدیۆی ئامادە — ڕاستەوخۆ بینێرە بۆ شاشەکە (H.264، 30fps، 720×200، 10s، loop ـی بێ پچڕان) |
| `index.html` | کۆدی ئەنیمەیشنەکە — ئەمە بخەرە ناو Canva Code |
| `render.mjs` | ڕێندەری کۆدەکە بۆ MP4 (`node render.mjs`) |

## تایم‌لاین
| کات | چی ڕوودەدات |
|---|---|
| 0.0–0.9 | تیشکێکی سکان لە چەپەوە دێت و شاشەکە "دادەگیرسێنێت" |
| 0.7–3.5 | WASTA و GHAREB لە دوو لاوە پێکدەدەن، تەقینەوەی ڕووناکی، مەدالیای WG + 5 ئەستێرە |
| 3.5–6.6 | لۆگۆکە بە ناوەڕاستدا دەبڕدرێت، «وەستا غەریب» بە زێڕین لە ڕاستەوە بۆ چەپ دەنووسرێت |
| 6.1–9.2 | پەڕەیەکی زێڕین دادەپۆشێت: WELCOME ★ بەخێربێن، لێدانی دڵ |
| 9.2–10 | تیشکەکە دەگەڕێتەوە و شاشە دەگەڕێتەوە سەر فرەیمی یەکەم (loop) |

## Canva Code — هەنگاوەکان
1. لە Canva → **Canva Code** (ئەو شاشەیەی «Describe your idea»).
2. ئەم دەقەی خوارەوە کۆپی بکە، پاشان **هەموو ناوەڕۆکی `index.html`** لە ژێریدا بلکێنە، بینێرە:

```
Build this EXACT HTML file as-is. Do not redesign it and do not change sizes,
colors, fonts, text or timings. It is a 720x200 px canvas animation for an LED
shop sign that loops every 10 seconds. Keep the canvas at exactly 720x200 and
scale it to fit the preview. Here is the code:
```

3. ئەگەر Canva وتی دەقەکە زۆر درێژە، ئەم پرۆمپتە کورتە بەکاربهێنە (Canva خۆی کۆد دەنووسێت، بەڵام ئەنجامەکەی وەک ئەوەی من نابێت):

```
Create a 10-second seamless looping canvas animation, exactly 720x200 px, for an
LED shop sign. Dark navy background with a subtle animated blue LED dot grid.
0-0.9s: a bright cyan vertical scan beam sweeps left to right and lights the grid.
0.7-3.5s: "WASTA" slams in from the left and "GHAREB" from the right (bold condensed
font like Anton, white with blue glow, motion trails), impact flash + shockwave ring,
then a round navy medallion pops in the center with gold "WG" and 5 small gold stars,
a light glint sweeps across. 3.5-6.6s: the lockup is sliced horizontally (top half
moves up, bottom half down) revealing the Kurdish text "وەستا غەریب" in gold
(Noto Kufi Arabic Black) revealed right-to-left, with rising gold sparks.
6.1-9.2s: a diagonal gold panel wipes in from the right: "WELCOME" (navy, letters
drop in one by one) | navy circle with rotating gold star | "بەخێربێن" (navy).
9.2-10s: the scan beam sweeps back right-to-left and returns to the first frame.
```

## ڕاستگۆیی گرنگ
- **Canva Code بۆ تاقیکردنەوە و بینینە.** دڵنیا نیم Canva ئەنیمەیشنی ناو کۆد بە MP4 دەربهێنێت (زۆرجار تەنها وێنەیەکی وەستاو دەردەکات). بۆ شاشەکە **MP4 ـەکە بەکاربهێنە** — ئەوەم فرەیم بە فرەیم و بە قەبارەی ڕاست 720×200 دروست کردووە.
- Screen record لە مۆبایل **مەکە** — قەبارەکە دەشێوێت و شاشەکە تەڵخ دەبێت.

## ناردن بۆ شاشەکە (ئەپی LED)
Program → **+** → شاشەی `wastaghareb (A4L 720*200)` → Add → بەشی ڤیدیۆ زیاد بکە → MP4 ـەکە هەڵبژێرە → ناوچەکە بکە بە تەواوی شاشە (x=0, y=0, 720×200) → Send.

## گۆڕینی ناوەڕۆک
لە سەرەتای `<script>` ـی `index.html`:
- `TXT` — هەموو نووسینەکان (بۆ نموونە `en2:"OPEN NOW"`).
- `LOGO_URL` — لینکی PNG ـی لۆگۆکەت (پاشبنەمای ڕوون) دابنێ، لە جیاتی WG دەردەکەوێت.
پاشان `node render.mjs` بۆ MP4 ـی نوێ.
