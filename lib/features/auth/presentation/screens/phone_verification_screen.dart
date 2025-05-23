import 'dart:async';
import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
  }) : super(key: key);

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _currentCode = '';
  int _resendCountdown = 60;
  Timer? _resendTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _verifyCode() {
    if (_currentCode.length == 6) {
      HapticFeedback.mediumImpact();
      context.read<AuthBloc>().add(
        VerifyPhoneCodeEvent(
          smsCode: _currentCode,
          verificationId: widget.verificationId,
        ),
      );
    }
  }

  void _resendCode() {
    if (_canResend) {
      HapticFeedback.lightImpact();
      _startResendTimer();
      context.read<AuthBloc>().add(
        SendPhoneCodeEvent(phoneNumber: widget.phoneNumber),
      );
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          } else if (state is AuthenticationFailure) {
            HapticFeedback.heavyImpact();
            _showSnackBar(
              state.message,
              Colors.red.shade600,
              Icons.error_outline,
            );
            _codeController.clear();
            setState(() => _currentCode = '');
          } else if (state is PhoneVerificationSent) {
            _showSnackBar(
              'New verification code sent',
              Colors.green.shade600,
              Icons.check_circle_outline,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is Authenticating;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildCodeInput(isLoading),
                    _buildVerifyButton(isLoading),
                    const SizedBox(height: 24),
                    _buildResendRow(isLoading),
                    const SizedBox(height: 32),
                    _buildInfoBox(),
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE57373),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFE57373).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.message_rounded,
            size: 50,
            color: Color(0xFFE57373),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verification',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Code sent to ${widget.phoneNumber}',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeInput(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PinCodeTextField(
        appContext: context,
        length: 6,
        controller: _codeController,
        onChanged: (value) => setState(() => _currentCode = value),
        onCompleted: (_) => !isLoading ? _verifyCode() : null,
        enabled: !isLoading,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(12),
          fieldHeight: 56,
          fieldWidth: 46,
          activeFillColor: Colors.white,
          inactiveFillColor: Colors.white,
          selectedFillColor: Colors.white,
          activeColor: const Color(0xFFE57373),
          inactiveColor: Colors.grey.shade300,
          selectedColor: const Color(0xFFE57373),
          borderWidth: 2,
        ),
        animationType: AnimationType.fade,
        enableActiveFill: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    final isEnabled = _currentCode.length == 6 && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _verifyCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE57373),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEnabled ? 4 : 0,
        ),
        child: Text(
          'Verify Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildResendRow(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed: _canResend && !isLoading ? _resendCode : null,
          child: Text(
            _canResend ? 'Resend' : 'Wait $_resendCountdown s',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _canResend ? const Color(0xFFE57373) : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Check your cellular signal\n'
            '• SMS may take up to 60 seconds\n'
            '• Verify your phone number is correct',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
