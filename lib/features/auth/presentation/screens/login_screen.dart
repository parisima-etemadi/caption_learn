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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
          SignInWithEmailPasswordRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
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
   // context.read<AuthBloc>().add(SignInWithAppleRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticationFailure) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildLogo(),
                const SizedBox(height: 32),
                _buildLoginForm(context, state),
                const SizedBox(height: 16),
                _buildForgotPassword(),
                const SizedBox(height: 24),
                _buildSocialLoginDivider(),
                const SizedBox(height: 24),
                _buildSocialLoginButtons(context, state),
                const SizedBox(height: 24),
                _buildSignUpOption(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return const Icon(Icons.closed_caption, size: 80, color: Colors.blue);
  }

  Widget _buildLoginForm(BuildContext context, AuthState state) {
    final isLoading = state is Authenticating;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : () => _submitForm(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        // Implement forgot password functionality
      },
      child: const Text('Forgot Password?'),
    );
  }

  Widget _buildSocialLoginDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey,
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
        const SizedBox(width: 16),
        // Apple Sign-In Button
        SocialIconButton.apple(
          onPressed: () => _signInWithApple(context),
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildSignUpOption(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SignupScreen(),
          ),
        );
      },
      child: const Text('Don\'t have an account? Register'),
    );
  }
}