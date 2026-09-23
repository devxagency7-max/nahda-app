import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class EditableTextField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool readOnly;
  final bool enabled;
  final Widget? suffixIcon;

  const EditableTextField({
    super.key,
    required this.label,
    this.required = false,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.errorText,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged,
        readOnly: readOnly,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          counterText: '',
          errorText: errorText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
