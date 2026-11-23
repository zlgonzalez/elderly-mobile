import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../family_portal/resident_provider.dart';
import 'auth_provider.dart';

class CaregiverFinalizeSignUpScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const CaregiverFinalizeSignUpScreen({
    super.key,
    this.initialEmail,
  });

  @override
  ConsumerState<CaregiverFinalizeSignUpScreen> createState() =>
      _CaregiverFinalizeSignUpScreenState();
}

class _CaregiverFinalizeSignUpScreenState
    extends ConsumerState<CaregiverFinalizeSignUpScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _usernameEditedManually = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmail?.trim().isNotEmpty == true
        ? widget.initialEmail!.trim()
        : (ref.read(authProvider).pendingSignUpEmail ?? '');
    if (initial.isNotEmpty) {
      _emailController.text = initial;
      _usernameController.text = _deriveEmailPrefix(initial);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _deriveEmailPrefix(String email) {
    final trimmed = email.trim().toLowerCase();
    if (!trimmed.contains('@')) return trimmed;
    return trimmed.split('@').first;
  }

  Future<void> _handleFinalize() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).finalizeCaregiverSignUp(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (success) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref
            .read(residentProvider.notifier)
            .selectById(user.linkedResidentId);
      }
      if (mounted) {
        context.go('/portal');
      }
    }
  }

  Future<void> _handleResendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return;
    }
    await ref.read(authProvider.notifier).resendCaregiverSignUpCode(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finalize Caregiver Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/signup'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Complete Your Caregiver Account',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit verification code from your email, confirm or customize your username, and create your password.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (authState.errorMessage != null) ...[
                      Container(
                        key: const Key('finalize_error_banner'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.allergyRedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.allergyRed.withAlpha(50)),
                        ),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.allergyRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (authState.infoMessage != null) ...[
                      Container(
                        key: const Key('finalize_info_banner'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(80)),
                        ),
                        child: Text(
                          authState.infoMessage!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Email Address',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('finalize_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      onChanged: (value) {
                        if (!_usernameEditedManually) {
                          _usernameController.text = _deriveEmailPrefix(value);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter your email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter your email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '6-Digit Verification Code',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('finalize_code_field'),
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: 'Enter 6-digit code from email',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                        counterText: '',
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.length != 6 ||
                            int.tryParse(trimmed) == null) {
                          return 'Please enter the 6-digit verification code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Caregiver Username',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('finalize_username_field'),
                      controller: _usernameController,
                      autocorrect: false,
                      onChanged: (_) => _usernameEditedManually = true,
                      decoration: const InputDecoration(
                        hintText: 'Choose your caregiver username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.length < 3 || trimmed.length > 64) {
                          return 'Username must be 3 to 64 characters';
                        }
                        if (trimmed.contains(' ')) {
                          return 'Username cannot contain spaces';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('finalize_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Create a password (min. 8 characters)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Password',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('finalize_confirm_password_field'),
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Re-enter your password',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('finalize_submit_button'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: authState.isLoading ? null : _handleFinalize,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Complete Sign Up'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('finalize_resend_code_button'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: authState.isLoading ? null : _handleResendCode,
                      child: const Text('Resend 6-Digit Verification Email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
