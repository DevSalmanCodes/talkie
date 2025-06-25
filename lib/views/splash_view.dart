import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:talkie/constants/color_constants.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/widgets/loader.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() {
    ref.read(firebaseAuthProvider).authStateChanges().listen((user) {
      if (user == null) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.login,
            (route) => false,
          );
        });
      } else {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.navBar,
            (route) => false,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SvgPicture.asset('assets/chat.svg', height: 120.0),
              ),
              const Loader(color: ColorConstants.whiteColor),
              const SizedBox(height: 60.0),
            ],
          ),
        ),
      ),
    );
  }
}
