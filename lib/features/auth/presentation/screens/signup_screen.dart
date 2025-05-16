import 'package:caption_learn/features/auth/domain/utils/password_utils.dart';
import 'package:caption_learn/features/auth/domain/validator/auth_validators.dart';
import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:caption_learn/features/auth/presentation/widgets/auth_text_form_field.dart';
import 'package:caption_learn/features/auth/presentation/widgets/password_text_form_field.dart';
import 'package:caption_learn/features/auth/presentation/widgets/social_login_section.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  CountryCode _selectedCountry = CountryCode.fromCountryCode('US');
  PasswordStrength _passwordStrength = PasswordUtils.calculateStrength('');

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _suggestPassword() {
    final password = PasswordUtils.generateStrongPassword();
    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // Format phone with selected country code
    final phoneNumber = "${_selectedCountry.dialCode}${_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}";
    
    context.read<AuthBloc>().add(SendPhoneCodeEvent(phoneNumber: phoneNumber));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: _authStateListener,
            builder: (context, state) {
              final isLoading = state is Authenticating;
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildContent(isLoading),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 40),
        _buildForm(isLoading),
        const SizedBox(height: 24),
        _buildSignUpButton(isLoading),
        const SizedBox(height: 24),
        SocialLoginSection(
          isLoading: isLoading,
          dividerText: 'or continue with',
          onGoogleSignIn: () => context.read<AuthBloc>().add(SignInWithGoogleRequested()),
          onAppleSignIn: () => context.read<AuthBloc>().add(SignInWithAppleRequested()),
        ),
        const SizedBox(height: 24),
        _buildLoginOption(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please fill in the form to continue',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone number field with country picker
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CountryCodePicker(
                  onChanged: (CountryCode code) {
                    setState(() => _selectedCountry = code);
                  },
                  initialSelection: 'US',
                  favorite: const ['US', 'GB', 'IR', 'CA', 'DE', 'FR', 'IN'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  showFlag: true,
                  flagWidth: 24,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: AuthValidators.validatePhone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Password field
          PasswordTextFormField(
            controller: _passwordController,
            hintText: 'Password',
            enabled: !isLoading,
            showStrengthIndicator: true,
            onSuggestPassword: _suggestPassword,
            onStrengthChanged: (strength) => setState(() => _passwordStrength = strength),
            validator: (value) => AuthValidators.validatePassword(
              value,
              hasMinLength: _passwordStrength.hasMinLength,
              hasLetterAndNumber: _passwordStrength.hasLetterAndNumber,
              hasSpecialChar: _passwordStrength.hasSpecialChar,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Confirm password field
          PasswordTextFormField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            enabled: !isLoading,
            validator: (value) => AuthValidators.validateConfirmPassword(
              value, 
              _passwordController.text
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE57373),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 56),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Create Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLoginOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account?', style: TextStyle(color: Colors.grey.shade600)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    if (state is RegistrationFailure || state is AuthenticationFailure) {
      final message = state is RegistrationFailure 
          ? (state as RegistrationFailure).message 
          : (state as AuthenticationFailure).message;
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } else if (state is PhoneVerificationSent) {
      // Navigator to verification screen would go here
    } else if (state is Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}