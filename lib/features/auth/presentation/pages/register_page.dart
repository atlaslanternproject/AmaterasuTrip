import 'package:flutter/material.dart';
import '../../../../core/widgets/layout/Amaterasu_background.dart';
import '../../../../core/widgets/layout/Amaterasu_hero.dart';
import '../widgets/register_card.dart';
class RegisterPage extends StatelessWidget {
  const RegisterPage({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmaterasuBackground(
       child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AmaterasuHero(),
                        const SizedBox(height: 12),
                        const RegisterCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

