import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'auth_background.dart';
import 'primary_button.dart';

/// Complete auth form widget - reduces duplication across auth screens
class AuthForm extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String buttonText;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final Widget? bottomWidget;
  
  const AuthForm({
    super.key,
    required this.title,
    required this.fields,
    required this.buttonText,
    this.onSubmit,
    this.isLoading = false,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ...fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: field,
                )),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: buttonText,
                  onPressed: onSubmit,
                  isLoading: isLoading,
                ),
                if (bottomWidget != null) ...[
                  const SizedBox(height: 24),
                  bottomWidget!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple phone input field
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(CountryCode)? onCountryChanged;
  
  const PhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: onCountryChanged,
            initialSelection: '+1',
            favorite: const ['+1', '+44', '+91'],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone number',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple text field
class SimpleField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  
  const SimpleField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}