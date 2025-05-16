import 'package:caption_learn/core/widgets/network_error_widget.dart';
import 'package:caption_learn/features/auth/domain/validator/auth_validators.dart';
import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:caption_learn/features/auth/presentation/screens/signup_screen.dart';
import 'package:caption_learn/features/auth/presentation/widgets/auth_text_form_field.dart';
import 'package:caption_learn/features/auth/presentation/widgets/social_login_section.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = CountryCode.fromCountryCode('US');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // Format phone with country code
    final phoneNumber = "${_selectedCountry.dialCode}${_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}";
    
    context.read<AuthBloc>().add(SendPhoneCodeEvent(phoneNumber: phoneNumber));
  }

  Future<void> _signInWithGoogle() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult.isNotEmpty && 
                        connectivityResult.first != ConnectivityResult.none;
    
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    context.read<AuthBloc>().add(SignInWithGoogleRequested());
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
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _authStateListener,
          builder: (context, state) {
            // Show error widget for network errors
            if (state is AuthenticationFailure && 
                (state.message.contains('network') || 
                 state.message.contains('connection') ||
                 state.message.contains('internet'))) {
              return NetworkErrorWidget(
                message: state.message,
                onRetry: _signInWithGoogle,
              );
            }
            
            final isLoading = state is Authenticating;
            
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildContent(isLoading),
                  ),
                ),
              ),
            );
          },
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
        _buildLoginForm(isLoading),
        const SizedBox(height: 16),
        _buildForgotPassword(),
        const SizedBox(height: 24),
        _buildSignInButton(isLoading),
        const SizedBox(height: 24),
        SocialLoginSection(
          isLoading: isLoading,
          dividerText: 'Or continue with',
          onGoogleSignIn: _signInWithGoogle,
          onAppleSignIn: () => context.read<AuthBloc>().add(SignInWithAppleRequested()),
        ),
        const SizedBox(height: 24),
        _buildSignUpOption(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Text(
          'Hello Again!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Welcome back you\'ve been missed!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Implement forgot password functionality
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Recovery Phone Number'),
      ),
    );
  }

  Widget _buildSignInButton(bool isLoading) {
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
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildSignUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Not a member?', style: TextStyle(color: Colors.grey.shade600)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text('Register now', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    if (state is AuthenticationFailure) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    } else if (state is PhoneVerificationSent) {
      // Navigate to verification screen would go here
      // Navigator.push(...);
    }
  }
}