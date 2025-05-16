import 'package:caption_learn/core/widgets/social_icon_button.dart';
import 'package:caption_learn/features/auth/domain/validator/auth_validators.dart';
import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:caption_learn/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:caption_learn/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:caption_learn/features/auth/presentation/widgets/social_login_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';


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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Password strength variables
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _strengthColor = Colors.grey;
  bool _hasMinLength = false;
  bool _hasLetterAndNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    
    // Check minimum 8 characters
    _hasMinLength = password.length >= 8 && password.length <= 20;
    
    // Check for at least one letter and one number
    _hasLetterAndNumber = RegExp(r'(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(password);
    
    // Check for at least one special character
    _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    // Calculate strength
    int strength = 0;
    if (_hasMinLength) strength++;
    if (_hasLetterAndNumber) strength++;
    if (_hasSpecialChar) strength++;
    
    if (password.isEmpty) {
      _passwordStrength = 0;
      _passwordStrengthText = '';
      _strengthColor = Colors.grey.shade400;
    } else if (strength == 1) {
      _passwordStrength = 0.33;
      _passwordStrengthText = 'Weak';
      _strengthColor = Colors.red;
    } else if (strength == 2) {
      _passwordStrength = 0.66;
      _passwordStrengthText = 'Medium';
      _strengthColor = Colors.orange;
    } else if (strength == 3) {
      _passwordStrength = 1.0;
      _passwordStrengthText = 'Strong';
      _strengthColor = Colors.green;
    }
    
    setState(() {});
  }
  
  String _generateStrongPassword() {
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String specialChars = '!@#\$%^&*(),.?":{}|<>';
    
    final Random random = Random.secure();
    
    // Ensure at least one of each type of character
    String password = '';
    password += upperCase[random.nextInt(upperCase.length)];
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += specialChars[random.nextInt(specialChars.length)];
    
    // Add more random characters
    const String allChars = upperCase + lowerCase + numbers + specialChars;
    final int remainingLength = 8 + random.nextInt(8); // Length between 8-16 chars
    
    for (int i = 0; i < remainingLength - 4; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }
    
    // Shuffle the password characters
    List<String> passwordChars = password.split('');
    passwordChars.shuffle(random);
    return passwordChars.join('');
  }
  
  void _suggestPassword() {
    final String password = _generateStrongPassword();
    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
      
      // Update the UI for password strength
      _checkPasswordStrength();
    });
  }

  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Format phone with country code
    final phoneNumber = "+98${_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}";
    
    context.read<AuthBloc>().add(
      SendPhoneCodeEvent(
        phoneNumber: phoneNumber,
      ),
    );
  }

  void _signInWithGoogle(BuildContext context) {
    context.read<AuthBloc>().add(SignInWithGoogleRequested());
  }

  void _signInWithApple(BuildContext context) {
    context.read<AuthBloc>().add(SignInWithAppleRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE8EAF6),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: _authStateListener,
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 50),
                        _buildForm(context, state),
                        const SizedBox(height: 24),
                        _buildSignUpButton(context, state),
                        const SizedBox(height: 24),
                        SocialLoginSection(
                          isLoading: state is Authenticating,
                          dividerText: 'or continue with',
                          onGoogleSignIn: () => _signInWithGoogle(context),
                          onAppleSignIn: () => _signInWithApple(context),
                        ),
                        const SizedBox(height: 24),
                        _buildLoginOption(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    if (state is RegistrationFailure || state is AuthenticationFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state is RegistrationFailure 
              ? (state as RegistrationFailure).message 
              : (state as AuthenticationFailure).message),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state is PhoneVerificationSent) {
      // Navigate to verification screen
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PhoneVerificationScreen(
      //       verificationId: state.verificationId,
      //       phoneNumber: state.phoneNumber,
      //     ),
      //   ),
      // );
    } else if (state is Authenticated) {
      // User authenticated successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please fill in the form to continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthState state) {
    final isLoading = state is Authenticating;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInputField(
            controller: _phoneController,
            hintText: 'Phone Number',
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
            prefix: '+98',
            validator: AuthValidators.validatePhone,
          ),
          const SizedBox(height: 16),
          
          AuthInputField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: _obscurePassword,
            enabled: !isLoading,
            suffix: _buildVisibilityToggle(_obscurePassword, () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            }),
            validator: (value) => AuthValidators.validatePassword(value, hasMinLength: _hasMinLength, hasLetterAndNumber: _hasLetterAndNumber, hasSpecialChar: _hasSpecialChar),
          ),
          
          const SizedBox(height: 16),
          
          AuthInputField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            obscureText: _obscureConfirmPassword,
            enabled: !isLoading,
            suffix: _buildVisibilityToggle(_obscureConfirmPassword, () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            }),
            validator: (value) => AuthValidators.validateConfirmPassword(value, _passwordController.text),
          ),
          
          TextButton.icon(
            onPressed: _suggestPassword,
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('Suggest Password'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              alignment: Alignment.centerLeft,
            ),
          ),
          
          const SizedBox(height: 24),
          PasswordStrengthIndicator(
            strength: _passwordStrength,
            strengthText: _passwordStrengthText,
            strengthColor: _strengthColor,
            hasMinLength: _hasMinLength,
            hasLetterAndNumber: _hasLetterAndNumber,
            hasSpecialChar: _hasSpecialChar,
          ),
        ],
      ),
    );
  }

 



  Widget _buildVisibilityToggle(bool isObscured, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSignUpButton(BuildContext context, AuthState state) {
    final isLoading = state is Authenticating;
    
    return ElevatedButton(
      onPressed: isLoading ? null : () => _submitForm(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE57373),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }



  

  Widget _buildLoginOption(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}