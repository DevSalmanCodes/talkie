import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talkie/constants/color_constants.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool? obsecureText;
  final VoidCallback? onPressed;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.controller,
    this.validator,
    this.obsecureText,
    this.onPressed,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      obscureText: obsecureText ?? false,
      validator: validator,
      controller: controller,
      style: const TextStyle(color: ColorConstants.whiteColor),
      decoration: InputDecoration(
        labelStyle: const TextStyle(color: ColorConstants.whiteColor),
        suffixIcon: obsecureText != null
            ? IconButton(
                onPressed: onPressed,
                icon: Icon(
                  obsecureText ?? false ? LucideIcons.eye : LucideIcons.eyeOff,
                ),
              )
            : null,
        border: const OutlineInputBorder(),
        labelText: labelText,
      ),
    );
  }
}
