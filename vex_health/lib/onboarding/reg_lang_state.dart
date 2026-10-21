// VEX Health — زمانی هەڵبژێردراو (بۆ بەشی سەرەتا)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reg_lang_data.dart';

RLang langOf(String code) => kLangs.firstWhere((l) => l.code == code, orElse: () => kLangs[1]);

TextDirection dirOfLang(RLang l) => l.rtl ? TextDirection.rtl : TextDirection.ltr;

class LangState extends ChangeNotifier {
  LangState._();
  static final LangState I = LangState._();

  static const String kKey = 'vexlang';

  /// کۆدی زمانی هەڵبژێردراو (بنەڕەت: کوردی سۆرانی)
  String code = 'ckb';

  /// ئایا بەکارهێنەر پێشتر زمانی هەڵبژاردووە؟ (نەخێر ← یەکەم شاشە هەڵبژاردنی زمانە)
  bool chosen = false;

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = sp.getString(kKey);
      if (v != null && kLangs.any((l) => l.code == v)) {
        code = v;
        chosen = true;
      }
    } catch (_) {}
  }

  Future<void> set(String c) async {
    if (!kLangs.any((l) => l.code == c)) return;
    code = c;
    chosen = true;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(kKey, c);
    } catch (_) {}
  }

  RLang get cur => langOf(code);
  String t(String k) => cur.t[k] ?? '';
  bool get isKu => code == 'ckb' || code == 'kmr';
}
