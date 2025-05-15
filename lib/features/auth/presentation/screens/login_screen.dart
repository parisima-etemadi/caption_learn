// lib/features/auth/presentation/screens/login_screen.dart
import 'package:caption_learn/core/constants/app_constants.dart';
import 'package:caption_learn/core/widgets/network_error_widget.dart';
import 'package:caption_learn/core/widgets/social_icon_button.dart';
import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:caption_learn/features/auth/presentation/screens/signup_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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

  void _signInWithGoogle(BuildContext context) async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;
    
    if (!isConnected) {
      // Show a snackbar if there's no connection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network settings and try again.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
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
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthenticationFailure) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
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
            }
          },
          builder: (context, state) {
            // Show error widget for network errors
            if (state is AuthenticationFailure && 
                (state.message.contains('network') || 
                 state.message.contains('connection') ||
                 state.message.contains('internet'))) {
              return NetworkErrorWidget(
                message: state.message,
                onRetry: () => _signInWithGoogle(context),
              );
            }
            
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 50),
                          _buildLoginForm(context, state),
                          const SizedBox(height: 16),
                          _buildForgotPassword(),
                          const SizedBox(height: 24),
                          _buildSignInButton(context, state),
                          const SizedBox(height: 24),
                          _buildSocialLoginDivider(),
                          const SizedBox(height: 24),
                          _buildSocialLoginButtons(context, state),
                          const SizedBox(height: 24),
                          _buildSignUpOption(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Hello Again!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Welcome back you\'ve been missed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState state) {
    final isLoading = state is Authenticating;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone Number',
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
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: const Text(
                  "+98", // USA code - update as needed
                  style: TextStyle(fontSize: 16),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              
              // Simple phone validation - modify as needed
              final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (cleanPhone.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
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

  Widget _buildSignInButton(BuildContext context, AuthState state) {
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
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildSocialLoginDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons(BuildContext context, AuthState state) {
    final isLoading = state is Authenticating;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Sign-In Button
        SocialIconButton.google(
          onPressed: () => _signInWithGoogle(context),
          isLoading: isLoading,
        ),
        const SizedBox(width: 24),
        // Apple Sign-In Button
        SocialIconButton.apple(
          onPressed: () => _signInWithApple(context),
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildSignUpOption(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Not a member?',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Register now',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}