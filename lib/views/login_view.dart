import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkie/constants/size_constants.dart';
import 'package:talkie/constants/text_style_constants.dart';
import 'package:talkie/constants/validation_constants.dart'
    show ValidationConstants;
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/auth_view_model.dart';
import 'package:talkie/widgets/custom_button.dart';
import 'package:talkie/widgets/custom_text_field.dart';
import 'package:talkie/widgets/loader.dart';

import '../providers/general_providers.dart';
import '../utils/methods.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_formKey.currentState!.validate()) {
      if (email.isEmpty || password.isEmpty) {
        showToast('Please fill all the fields');
      } else {
        ref
            .read(authViewModelProvider.notifier)
            .login(email, password, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider);
    final width = SizeConstants.width(context);
    final height = SizeConstants.height(context);
    bool isObsecure = ref.watch(obsecureProvider);
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SizeConstants.smallPadding + 4.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: height * 0.2),
                          Text(
                            'Welcome Back!',
                            style: TextStyleConstants.boldTextStyle.copyWith(
                              fontSize: 25,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          CustomTextField(
                            labelText: 'Email',
                            controller: _emailController,
                            validator: ValidationConstants.isValidEmail,
                          ),
                          const SizedBox(height: 20.0),
                          CustomTextField(
                            labelText: 'Password',
                            controller: _passwordController,
                            validator: ValidationConstants.isValidPassword,
                            obsecureText: isObsecure,
                            onPressed: () =>
                                ref.read(obsecureProvider.notifier).state =
                                    !isObsecure,
                          ),
                          const SizedBox(height: 20.0),
                          CustomButton(
                            width: width,
                            onTap: _onLogin,
                            child: isLoading
                                ? const Loader(color: Colors.black)
                                : Text(
                                    'Login',
                                    style: TextStyleConstants.boldTextStyle
                                        .copyWith(color: Colors.black),
                                  ),
                          ),
                          const SizedBox(height: 12.0),
                          RichText(
                            text: TextSpan(
                              text: "Don't have an account?",
                              style: TextStyleConstants.semiBoldTextStyle
                                  .copyWith(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: " Sign Up",
                                  style: TextStyleConstants.boldTextStyle
                                      .copyWith(color: Colors.blue),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.pushNamed(
                                      context,
                                      RouteNames.signUp,
                                    ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
