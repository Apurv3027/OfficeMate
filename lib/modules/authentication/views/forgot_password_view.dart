import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_validators.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_reset, size: 64, color: Color(0xFF2563EB)),

              const SizedBox(height: 24),

              const Text(
                'Reset Your Password',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                'Enter your registered email address. '
                'We will send you a password reset link.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              controller.forgotPassword(emailController.text);
                            }
                          },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator()
                        : const Text('Send Reset Link'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
