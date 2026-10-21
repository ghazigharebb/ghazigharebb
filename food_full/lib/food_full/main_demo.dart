// خواردن کامل — تاقیکردنەوەی سەربەخۆ (بێ ئەپی VEX)
//
//   flutter run -t lib/food_full/main_demo.dart
import 'package:flutter/material.dart';

import 'vex_food_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خواردن کامل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const VexFoodPage(),
    );
  }
}
