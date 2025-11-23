import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_cups_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class SharedTab extends ConsumerWidget {
  const SharedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedCups = ref.watch(sharedCupsProvider);

    if (sharedCups.isEmpty) {
      return Center(
        child: Padding(
          padding: AppStyles.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 120,
                color: AppTheme.primaryBrown.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Shared Items Yet',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan QR codes or use links\nto see shared recipes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textGray,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: AppStyles.screenPadding,
      itemCount: sharedCups.length,
      itemBuilder: (context, index) {
        final sharedCup = sharedCups[index];
        final cup = sharedCup.cupData;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryBrown,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(cup.brewType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shared by ${sharedCup.originalUsername}'),
                Text(
                  'Received ${formatDate(sharedCup.sharedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Text('View Details'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'view') {
                  _viewSharedCup(context, sharedCup.id);
                } else if (value == 'delete') {
                  _deleteSharedCup(context, ref, sharedCup.id);
                }
              },
            ),
            onTap: () => _viewSharedCup(context, sharedCup.id),
          ),
        );
      },
    );
  }

  void _scanQRCode(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: const Text(
          'QR code scanning requires camera permissions and Firebase setup. '
          'This feature will be available after Firebase configuration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewSharedCup(BuildContext context, String sharedCupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shared Recipe'),
        content: const Text('Recipe details coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteSharedCup(BuildContext context, WidgetRef ref, String sharedCupId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Shared Recipe',
      message: 'Are you sure you want to delete this shared recipe?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      await ref.read(sharedCupsProvider.notifier).deleteSharedCup(sharedCupId);
      if (context.mounted) {
        showSuccess(context, 'Shared recipe deleted');
      }
    }
  }
}
