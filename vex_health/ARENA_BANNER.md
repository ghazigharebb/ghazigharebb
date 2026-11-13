# VEX Arena — بانەری ژمێرەری زیندوو (دیزاینی ٢)

## چی دەکات
- ٧ ڕۆژ پێش دەستپێکردنی Arena، لە ماڵەوە لە شوێنی دۆخی Band دەردەکەوێت.
- ژمێرەر چرکە بە چرکە: ڕۆژ : کاتژمێر : خولەک : چرکە (کاسە دەلەرێتەوە، خاڵی سەوز دەترووسکێتەوە).
- پەنجە لێدان ← یەکسەر پەڕەی «تۆمارکردن بۆ VEX Arena» (ناسنامە → شار → کارەکتەر → ڕێساکان).
- کاتێک ژمێرەر دەگاتە سفر ← بانەر بە نەرمی لادەچێت و دۆخی Band دەگەڕێتەوە.

## فایلەکان
| فایل | |
|---|---|
| `lib/arena/arena_countdown_banner.dart` | **نوێ** — `ArenaCountdownSlot` + `ArenaCountdownBanner` (سەربەخۆ، تەنها material) |
| `lib/arena/arena_host.dart` | `kArenaStartsAt`، `openArena(join: true)`، `HomeArenaSlot` |
| `lib/arena/vex_arena.dart` | `VexArenaPage(autoJoin: true)` ← دوای کردنەوە پەڕەی تۆمارکردن دەکاتەوە (ئەگەر تۆمار نەکرابێت) |
| `lib/home/home_screen.dart` | `BandStatus()` ← `HomeArenaSlot(fallback: BandStatus())` |
| `test/arena_banner_test.dart` | ٥ تاقیکردنەوە (هەموو سەرکەوتوو) |

## بۆ ئەپی ڕاستەقینە (کە کۆدەکەی جیاوازە)
تەنها ئەمە پێویستە، لە شوێنی بانەری دۆخی Band:
```dart
ArenaCountdownSlot(
  startsAt: kArenaStartsAt,                 // کاتی ڕاستەقینەی دەستپێکردن (باشترە لە سێرڤەرەوە)
  onTap: () => /* پەڕەی تۆمارکردن بۆ VEX Arena بکەرەوە */,
  fallback: const BandStatus(),             // بانەری دۆخی Band ی ئێستاتان
)
```
⚠️ `kArenaStartsAt` ئێستا `2026-11-20 10:00` ـە (نموونە) — بیگۆڕە بۆ ڕێکەوتی ڕاستەقینە.
