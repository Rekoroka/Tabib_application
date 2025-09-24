import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/tabib_background.jpg"),
          fit: BoxFit.cover, // الصورة تملأ الشاشة
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
