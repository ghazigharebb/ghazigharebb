# VEX Health — پێوانەی ECG (دیزاینی E، بەپێی SDK ی J-Style V8)

## فایلەکان
| فایل | چی دەکات |
|---|---|
| `lib/ecg/ecg_page.dart` | 4 شاشە: ڕێنمایی (چەپ/ڕاست + 4 ئامۆژگاری) ← پێوانە (پەنجەی بزۆک، ئینجا شەپۆلی زیندوو، 30 چرکە) ← ڕاپۆرت (ئەنجام، هێڵکاری، کاغەزی ECG) ← مێژوو. 6 زمان، سپی/تاریک/خۆکار |
| `lib/ecg/ecg_i18n.dart` | هەموو دەقەکان بە 6 زمان (ckb، kmr، en، ar، fa، tr) |
| `lib/ecg/ecg_history.dart` | مێژووی پێوانەکان (SharedPreferences، تا 30 پێوانە) |
| `lib/ecg/ecg_pdf.dart` | دروستکردن و ناردنی PDF ی ڕاپۆرت (pdf + share_plus) |
| `lib/ecg/ecg_controller.dart` | فرمانی Band (measure 0x28 ← stream 0x07)، حاڵەتەکان، 30 چرکە، JSON ی ئەنجام |
| `lib/ecg/ecg_signal.dart` | 255Hz، پەنجەرەی 5 چرکە، پڕکردنەوەی پاکێتی ونبوو بە packetID، فلتەر، Pan–Tompkins، HRV |
| `assets/ecg/ecg_guide_{r,l}.webp`, `ecg_bg_{r,l}.webp`, `ecg_finger_{r,l}.webp` | وێنەی دەست و Band و پەنجە (ڕاست/چەپ) |
| `tools/ecg_check/ecg_dsp_ref.py` | تاقیکردنەوەی هەمان ماتماتیک |

`pubspec.yaml`: `assets/ecg/` و `pdf`، `share_plus` زیادکراون. Android/iOS: share_plus هیچ مۆڵەتێکی تایبەتی ناوێت.

## بانگکردن
`openEcgPage();` (لە home_cards.dart بەکارهاتووە)

## تێبینی
- وێنەی دەست/Band لە ئەپی فەرمیی JCVital وەرگیراون؛ بۆ بڵاوکردنەوە وێنەی ئەسڵی یان مۆڵەتی فرۆشیار وەرگرە.
- بۆ شوێنکەوتنی تەندروستیی گشتییە، نەک دەستنیشانکردنی نەخۆشی.
