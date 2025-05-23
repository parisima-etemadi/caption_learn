import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? prefix;
  final bool enabled;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextFormField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.prefix,
    this.enabled = true,
    this.validator,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      inputFormatters: inputFormatters ?? 
          (keyboardType == TextInputType.phone ? 
              [FilteringTextInputFormatter.digitsOnly] : null),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        suffixIcon: suffix,
        prefixIcon: prefix != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                alignment: Alignment.center,
                child: Text(
                  prefix!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              )
            : null,
        prefixIconConstraints: prefix != null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
      ),
      validator: validator,
    );
  }
}