import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../state/manager_state.dart';
import '../dashboard/guard_dashboard_screen.dart';
import '../dashboard/manager_dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _authenticateWithBiometrics() async {
    if (kIsWeb) {
      setState(() => _errorMessage = 'THIẾT BỊ KHÔNG HỖ TRỢ SINH TRẮC HỌC');
      return;
    }
    final lastGuard = ref
        .read(personnelProvider)
        .where((p) => p.id == ref.read(localStoreProvider)?.lastGuardId)
        .firstOrNull;
    if (lastGuard == null) {
      setState(() => _errorMessage = 'HÃY ĐĂNG NHẬP BẰNG PIN LẦN ĐẦU');
      return;
    }
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;

      if (!canAuthenticateWithBiometrics) {
        setState(() => _errorMessage = 'THIẾT BỊ KHÔNG HỖ TRỢ SINH TRẮC HỌC');
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Xác thực vân tay / khuôn mặt để đăng nhập ${lastGuard.name}',
      );

      if (didAuthenticate) {
        HapticFeedback.mediumImpact();
        if (!mounted) return;
        _enterAsGuard(lastGuard.id);
      }
    } on PlatformException catch (e) {
      setState(() => _errorMessage = 'LỖI SINH TRẮC HỌC: ${e.code}');
    } catch (_) {
      setState(() => _errorMessage = 'THIẾT BỊ KHÔNG HỖ TRỢ SINH TRẮC HỌC');
    }
  }

  void _enterAsGuard(String guardId) {
    ref.read(currentGuardIdProvider.notifier).state = guardId;
    ref.read(localStoreProvider)?.setLastGuardId(guardId);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const GuardDashboardScreen()));
  }

  void _onNumberPressed(String number) {
    HapticFeedback.lightImpact();
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
      if (_pin.length == 4) _submitPin();
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _submitPin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final guard = ref.read(personnelProvider.notifier).findByPin(_pin);
    if (_pin == kCommanderPin) {
      HapticFeedback.mediumImpact();
      ref.read(currentGuardIdProvider.notifier).state = null;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()));
    } else if (guard != null) {
      HapticFeedback.mediumImpact();
      _enterAsGuard(guard.id);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _errorMessage = 'TỪ CHỐI TRUY CẬP';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: primaryColor),
                const SizedBox(height: 24),
                const Text('HỆ THỐNG XÁC THỰC',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: 'Roboto',
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Bảo vệ: 1234 / 2345 / 3456 | Chỉ huy: 5678',
                    style:
                        TextStyle(color: Colors.white54, fontFamily: 'Roboto')),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: index < _pin.length
                              ? primaryColor
                              : Colors.transparent,
                          border: Border.all(color: primaryColor, width: 2)),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: primaryColor)
                      : Text(
                          _errorMessage ?? '',
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              letterSpacing: 1),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 32),
                AbsorbPointer(
                  absorbing: _isLoading,
                  child: Opacity(
                    opacity: _isLoading ? 0.5 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          _buildNumberRow(['1', '2', '3']),
                          const SizedBox(height: 16),
                          _buildNumberRow(['4', '5', '6']),
                          const SizedBox(height: 16),
                          _buildNumberRow(['7', '8', '9']),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildBiometricButton(),
                              _buildNumberButton('0'),
                              _buildDeleteButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberButton(n)).toList());

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3), width: 1)),
          child: Text(number,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto'))),
    );
  }

  Widget _buildDeleteButton() => InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: const Icon(Icons.backspace_outlined,
              size: 32, color: Colors.white54)));

  Widget _buildBiometricButton() {
    return InkWell(
        onTap: _authenticateWithBiometrics,
        borderRadius: BorderRadius.circular(40),
        child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.8), width: 2)),
            child: const Icon(Icons.fingerprint,
                size: 36, color: AppColors.primary)));
  }
}
