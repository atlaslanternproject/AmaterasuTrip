import 'package:flutter/material.dart';

class AmaterasuHero extends StatelessWidget {
  const AmaterasuHero({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 2),
        Image.asset(
          'assets/branding/banner_login.png',
          width: MediaQuery.of(context).size.width * 1.5,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
