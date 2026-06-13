import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/room_list_notifier.dart';

class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final code = _codeController.text.trim().toUpperCase();
    final success = await ref.read(roomListProvider.notifier).join(code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Join Room'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the invite code shared by the room owner',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g. ABC12345',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                helperText: '6-8 uppercase letters and numbers',
                counterText: '',
              ),
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter an invite code';
                }
                final code = v.trim().toUpperCase();
                if (code.length < 6 || code.length > 8) {
                  return 'Code must be 6-8 characters';
                }
                if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
                  return 'Code must contain only letters and numbers';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          label: 'Join',
          isLoading: _isLoading,
          icon: Icons.login_rounded,
          width: 100,
          height: 40,
          onPressed: _submit,
        ),
      ],
    );
  }
}
