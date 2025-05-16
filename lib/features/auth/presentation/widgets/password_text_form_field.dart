import 'package:caption_learn/features/auth/domain/utils/password_utils.dart';
import 'package:flutter/material.dart';
import 'package:caption_learn/features/auth/presentation/widgets/password_strength_indicator.dart';

class PasswordTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final Function(PasswordStrength)? onStrengthChanged;

  const PasswordTextFormField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.validator,
    this.showStrengthIndicator = false,
    this.onStrengthChanged,
  }) : super(key: key);

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscurePassword = true;
  late PasswordStrength _strength;

  @override
  void initState() {
    super.initState();
    _strength = PasswordUtils.calculateStrength(widget.controller.text);
    widget.controller.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updatePasswordStrength);
    super.dispose();
  }

  void _updatePasswordStrength() {
    final newStrength = PasswordUtils.calculateStrength(widget.controller.text);
    setState(() {
      _strength = newStrength;
    });
    
    if (widget.onStrengthChanged != null) {
      widget.onStrengthChanged!(_strength);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscurePassword,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
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
            suffixIcon: _buildVisibilityToggle(),
          ),
          validator: widget.validator,
        ),
          
        if (widget.showStrengthIndicator && widget.controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: PasswordStrengthIndicator(
              strength: _strength.score,
              strengthText: _strength.text,
              strengthColor: _strength.color,
              hasMinLength: _strength.hasMinLength,
              hasLetterAndNumber: _strength.hasLetterAndNumber,
              hasSpecialChar: _strength.hasSpecialChar,
            ),
          ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return IconButton(
      icon: Icon(
        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    );
  }
}