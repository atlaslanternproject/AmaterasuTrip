import 'package:flutter/material.dart';
import '../../../../core/widgets/layout/atlas_background.dart';
import '../../../../core/widgets/layout/atlas_hero.dart';
import '../widgets/login_card.dart';
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtlasBackground(
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
                        const AtlasHero(),
                        const SizedBox(height: 12),
                        const LoginCard(),
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
