import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';

class UsernamePromptDialog extends ConsumerStatefulWidget {
  const UsernamePromptDialog({super.key});

  @override
  ConsumerState<UsernamePromptDialog> createState() => _UsernamePromptDialogState();
}

class _UsernamePromptDialogState extends ConsumerState<UsernamePromptDialog> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(userProfileProvider.notifier).updateUsername(
        _usernameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving username: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _neverAskAgain() async {
    await ref.read(userProfileProvider.notifier).setNeverAskForUsername();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _dismiss() async {
    await ref.read(userProfileProvider.notifier).markAskedForUsername();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: AppTheme.primaryBrown,
          ),
          const SizedBox(width: 12),
          const Text('Create Your Username'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a username to identify your shared recipes and cups.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'coffeemaster',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username cannot be empty';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                  return 'Only letters, numbers, and underscores allowed';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveUsername(),
            ),
            const SizedBox(height: 12),
            Text(
              'You can change this later in your profile.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _neverAskAgain,
          child: const Text(
            'Never Ask Again',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _dismiss,
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUsername,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBrown,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
