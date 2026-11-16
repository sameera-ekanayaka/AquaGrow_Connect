import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/core/utils/validators.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen allowing the user to update their full name, farm name, and contact phone.
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Creates the edit profile screen.
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _farmController;
  late final TextEditingController _phoneController;

  String _initialName = '';
  String _initialFarm = '';
  String _initialPhone = '';
  bool _initialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _farmController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _populate(UserProfile user) {
    _initialName = user.fullName ?? '';
    _initialFarm = user.farmName ?? '';
    _initialPhone = user.phone ?? '';
    _nameController.text = _initialName;
    _farmController.text = _initialFarm;
    _phoneController.text = _initialPhone;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _nameController.text != _initialName ||
      _farmController.text != _initialFarm ||
      _phoneController.text != _initialPhone;

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    return await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: 'You have unsaved changes. Discard them?',
      confirmLabel: 'Discard',
      destructive: true,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success =
        await ref.read(authControllerProvider.notifier).updateProfile(
              fullName: _nameController.text.trim(),
              farmName: _farmController.text.trim().isEmpty
                  ? null
                  : _farmController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (!_initialized && user != null) {
      _populate(user);
    }

    return PopScope(
      canPop: !_isDirty && !_isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            // Each field checks itself as soon as the user types in it.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(AgSpace.screen),
              children: [
                TextFormField(
                  key: const Key('edit-profile-name'),
                  controller: _nameController,
                  validator: Validators.fullName,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AgSpace.s16),
                TextFormField(
                  key: const Key('edit-profile-farm'),
                  controller: _farmController,
                  decoration: const InputDecoration(
                    labelText: 'Farm name (optional)',
                    prefixIcon: Icon(Icons.agriculture_outlined),
                  ),
                ),
                const SizedBox(height: AgSpace.s16),
                TextFormField(
                  key: const Key('edit-profile-phone'),
                  controller: _phoneController,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AgSpace.s32),
                FilledButton(
                  key: const Key('edit-profile-save-btn'),
                  onPressed: _isLoading ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: AgColors.light.text,
                    minimumSize: const Size.fromHeight(kMinTouchTarget),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
