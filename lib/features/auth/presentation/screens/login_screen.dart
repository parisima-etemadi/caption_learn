import 'package:caption_learn/core/widgets/network_error_widget.dart';
import 'package:caption_learn/features/auth/domain/validator/auth_validators.dart';
import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:caption_learn/features/auth/presentation/screens/signup_screen.dart';
import 'package:caption_learn/features/auth/presentation/widgets/auth_text_form_field.dart';
import 'package:caption_learn/features/auth/presentation/widgets/social_login_section.dart';
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

  Future<void> _signInWithGoogle(BuildContext context) async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;
    
    if (!isConnected) {
      // Show a snackbar if there's no connection
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network settings and try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
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
          listener: _authStateListener,
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
            
            final isLoading = state is Authenticating;
            
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 50),
                        _buildLoginForm(context, isLoading),
                        const SizedBox(height: 16),
                        _buildForgotPassword(),
                        const SizedBox(height: 24),
                        _buildSignInButton(context, isLoading),
                        const SizedBox(height: 24),
                        SocialLoginSection(
                          isLoading: isLoading,
                          dividerText: 'Or continue with',
                          onGoogleSignIn: () => _signInWithGoogle(context),
                          onAppleSignIn: () => _signInWithApple(context),
                        ),
                        const SizedBox(height: 24),
                        _buildSignUpOption(context),
                      ],
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

  void _authStateListener(BuildContext context, AuthState state) {
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
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: AuthTextFormField(
        controller: _phoneController,
        hintText: 'Phone Number',
        keyboardType: TextInputType.phone,
        enabled: !isLoading,
        prefix: '+98',
        validator: AuthValidators.validatePhone,
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

  Widget _buildSignInButton(BuildContext context, bool isLoading) {
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