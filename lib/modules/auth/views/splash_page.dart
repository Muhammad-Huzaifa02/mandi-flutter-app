import 'package:flutter/material.dart';
import 'package:mandi/core/theme/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MGradient.primary),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 180),
              const SizedBox(height: MSpacing.sm),
              Text('Run your mandi business, digitally',
                  style: MText.bodyMd.copyWith(color: MColors.textOnDarkSub)),
              const SizedBox(height: MSpacing.xl),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
