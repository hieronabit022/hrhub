import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/auth_controller.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  bool otpRequested = false;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F2E8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF9F2E6),
              Color(0xFFF7F8FC),
              Color(0xFFF3EEFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  children: [
                    const _ReferenceHero(),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome to WorkPulse!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B2748),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      otpRequested
                          ? 'Enter the 4-digit verification code sent to your mobile number.'
                          : 'Your personal companion for employee attendance, requests, and approvals.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.8,
                        color: scheme.onSurfaceVariant,
                        height: 1.32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!otpRequested)
                      _DemoHint(
                        text: 'Demo Login\nAlya Rahman: 081234567890\nBima Prakoso: 081255500011\nCitra Lestari: 081277744455\nDimas Saputra: 081344455566\nNadia Putri: 081388899977\nOTP: 1234',
                      )
                    else
                      _DemoHint(
                        text: 'Demo OTP: 1234',
                      ),
                    const SizedBox(height: 14),
                    _FieldLabel(text: 'Mobile Number'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '08xxxxxxxxxx',
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                      ),
                    ),
                    if (otpRequested) ...[
                      const SizedBox(height: 12),
                      const _FieldLabel(text: 'Verification Code'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: otpController,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '1234',
                          counterText: '',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF17181F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: auth.loading
                            ? null
                            : () async {
                                final phone = phoneController.text.trim();
                                if (!otpRequested) {
                                  if (phone.isEmpty) {
                                    setState(() {
                                      errorText = 'Enter your mobile number first';
                                    });
                                    return;
                                  }
                                  try {
                                    await auth.requestOtp(phone);
                                    setState(() {
                                      otpRequested = true;
                                      errorText = null;
                                    });
                                  } catch (_) {
                                    setState(() {
                                      errorText = 'Mobile number was not found or the server could not be reached';
                                    });
                                  }
                                } else {
                                  final ok = await auth.verifyOtp(otpController.text.trim());
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    setState(() => errorText = 'Invalid verification code');
                                    return;
                                  }
                                  await context.read<AppController>().load();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                }
                              },
                        icon: const Icon(Icons.lock_open_rounded, size: 16),
                        label: Text(otpRequested ? 'Verify OTP' : 'Get OTP Code'),
                      ),
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

class _ReferenceHero extends StatelessWidget {
  const _ReferenceHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -18,
          top: 18,
          child: Container(
            width: 66,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE2D7FF).withValues(alpha: 0.7),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(66)),
            ),
          ),
        ),
        Positioned(
          left: -18,
          bottom: 24,
          child: Container(
            width: 52,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4BA).withValues(alpha: 0.7),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(52)),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(36),
          ),
          child: AspectRatio(
            aspectRatio: 0.96,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDCD9FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 22,
                    right: 22,
                    top: 22,
                    bottom: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A2B57),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    right: 36,
                    top: 36,
                    bottom: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D8FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 48,
                    top: 54,
                    child: _MiniPanel(icon: Icons.table_restaurant_rounded),
                  ),
                  const Positioned(
                    left: 102,
                    top: 48,
                    child: _MiniPanel(icon: Icons.check_box_outlined),
                  ),
                  const Positioned(
                    left: 156,
                    top: 54,
                    child: _MiniPanel(icon: Icons.article_outlined),
                  ),
                  Positioned(
                    left: 56,
                    bottom: 84,
                    child: Transform.rotate(
                      angle: -0.32,
                      child: const Icon(
                        Icons.laptop_mac_rounded,
                        size: 44,
                        color: Color(0xFF6040F3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 40,
                    bottom: 54,
                    child: Container(
                      width: 118,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6977FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 34,
                    top: 72,
                    child: Icon(
                      Icons.spa_rounded,
                      size: 76,
                      color: Color(0xFFC7D6FF),
                    ),
                  ),
                  Positioned(
                    right: 44,
                    bottom: 44,
                    child: SizedBox(
                      width: 120,
                      height: 168,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 28,
                            top: 42,
                            child: Container(
                              width: 52,
                              height: 68,
                              decoration: BoxDecoration(
                                color: const Color(0xFF986CFF),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 42,
                            top: 78,
                            child: Container(
                              width: 58,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6E72FF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 42,
                            top: 18,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFFFC39B),
                            ),
                          ),
                          const Positioned(
                            left: 46,
                            top: 42,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF7AA9FF),
                            ),
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 10,
                            child: Icon(
                              Icons.directions_run_rounded,
                              size: 46,
                              color: Color(0xFF695EFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPanel extends StatelessWidget {
  final IconData icon;

  const _MiniPanel({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _DemoHint extends StatelessWidget {
  final String text;

  const _DemoHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DCF8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.w700, height: 1.35),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
