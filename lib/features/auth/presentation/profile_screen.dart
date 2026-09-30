import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_profile.dart';
import 'auth_providers.dart';
import 'login_screen.dart';

/// User profile and session management screen.
/// Displays authenticated role, cryptographic keystore status, and hardware permissions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Account Profile', style: theme.textTheme.headlineSmall),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.statusCritical),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Identification Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primarySage.withValues(alpha: 0.3),
                      child: Text(
                        (user?.fullName?.isNotEmpty == true
                                ? user!.fullName![0]
                                : user?.email.isNotEmpty == true
                                    ? user!.email[0]
                                    : 'A')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.mintAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'AquaGrow Cultivator',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? AppConstants.mockOwnerEmail,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.mintAccent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              user?.role.displayName ?? 'System Owner',
                              style: const TextStyle(
                                color: AppColors.mintAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Role-Based Access Control (RBAC) Permissions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Access Control & Privileges',
                      style: TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      icon: Icons.tune_rounded,
                      title: 'Actuator Overrides & Dosing Pumps',
                      hasAccess: user?.canControlHardware ?? true,
                    ),
                    const Divider(color: AppColors.darkBorder, height: 20),
                    _buildPermissionRow(
                      icon: Icons.psychology_outlined,
                      title: 'Sensor Calibration & Threshold Editing',
                      hasAccess: user?.canControlHardware ?? true,
                    ),
                    const Divider(color: AppColors.darkBorder, height: 20),
                    _buildPermissionRow(
                      icon: Icons.query_stats_rounded,
                      title: 'Historical Telemetry & Chart Inspection',
                      hasAccess: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cryptographic Keystore Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: AppColors.mintAccent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hardware Security (Keystore / Keychain)',
                          style: TextStyle(
                            color: AppColors.textDarkPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Session tokens are encrypted using hardware-backed Android Keystore and iOS Keychain. Tokens never reside in unencrypted SharedPreferences.',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusOptimal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Hardware Encryption: Active',
                          style: TextStyle(
                            color: AppColors.statusOptimal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Registered Hydroponic Device Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Linked Hydroponic Hardware',
                          style: TextStyle(
                            color: AppColors.textDarkPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusOptimal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              color: AppColors.statusOptimal,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceDetail('Unit Name', 'AquaGrow Living Decor 01'),
                    _buildDeviceDetail('Serial Number', AppConstants.mockSerialNumber),
                    _buildDeviceDetail('System Topology', 'Nutrient Film Technique (NFT)'),
                    _buildDeviceDetail('Firmware', 'v1.0.4-esp32'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Sign Out Button
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out from Device'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusCritical,
                  side: const BorderSide(color: AppColors.statusCritical),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required bool hasAccess,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: hasAccess ? AppColors.mintAccent : AppColors.textDarkSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: hasAccess ? AppColors.textDarkPrimary : AppColors.textDarkSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Icon(
          hasAccess ? Icons.check_circle_rounded : Icons.cancel_outlined,
          size: 18,
          color: hasAccess ? AppColors.statusOptimal : AppColors.textDarkSecondary,
        ),
      ],
    );
  }

  Widget _buildDeviceDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
