import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

/// Reusable phone number input widget
class PhoneNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(CountryCode)? onCountryChanged;
  final String? hintText;
  final String initialCountryCode;
  
  const PhoneNumberInput({
    super.key,
    required this.controller,
    this.validator,
    this.onCountryChanged,
    this.hintText = 'Phone number',
    this.initialCountryCode = '+1',
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
            initialSelection: initialCountryCode,
            favorite: const ['+1', '+44', '+91'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}