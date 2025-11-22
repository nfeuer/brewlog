import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/drink_recipes_provider.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../services/photo_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import 'equipment_screen.dart';
import 'drink_recipe_book_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  int _clearDataPressCount = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final stats = ref.watch(userStatsProvider);
    final hasEquipment = ref.watch(hasEquipmentProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            tooltip: _isEditing ? 'Done' : 'Edit Profile',
          ),
        ],
      ),
      body: ListView(
        padding: AppStyles.screenPadding,
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: AppStyles.cardPadding,
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryBrown,
                        backgroundImage: user.profilePicturePath != null
                            ? FileImage(File(user.profilePicturePath!))
                            : null,
                        child: user.profilePicturePath == null
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryBrown,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              padding: EdgeInsets.zero,
                              onPressed: () => _showProfilePictureOptions(context, ref),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Centered username with edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: _isEditing ? () => _showEditNameDialog(context, ref, user.username) : null,
                          child: Text(
                            user.username ?? 'Coffee Enthusiast',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          color: AppTheme.primaryBrown,
                          onPressed: () => _showEditNameDialog(context, ref, user.username),
                          padding: const EdgeInsets.only(left: 4),
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  // Bio section with edit button
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _isEditing ? () => _showEditBioDialog(context, ref, user.bio) : null,
                            child: Text(
                              user.bio!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            color: Colors.grey[600],
                            onPressed: () => _showEditBioDialog(context, ref, user.bio),
                            padding: const EdgeInsets.only(left: 4),
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ] else if (_isEditing) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _showEditBioDialog(context, ref, null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add bio'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      user.isPaid ? 'PREMIUM' : 'FREE',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor:
                        user.isPaid ? Colors.amber : AppTheme.accentCream,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats dashboard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statistics', style: AppTextStyles.sectionHeader),
              TextButton.icon(
                onPressed: () => _recalculateStats(context, ref),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Recalculate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: AppStyles.cardPadding,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        context,
                        'Total Cups',
                        stats?.totalCupsMade.toString() ?? '0',
                        Icons.local_cafe,
                      ),
                      _buildStat(
                        context,
                        'Total Bags',
                        stats?.totalBagsPurchased.toString() ?? '0',
                        Icons.inventory_2,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        context,
                        'Coffee Used',
                        '${(stats?.totalGramsUsed ?? 0).toStringAsFixed(0)}g',
                        Icons.scale,
                      ),
                      _buildStat(
                        context,
                        'Brewed',
                        '${(stats?.totalMlConsumed ?? 0).toStringAsFixed(0)}ml',
                        Icons.local_drink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Brew types breakdown
          if (stats != null && stats.cupsByBrewType.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: AppStyles.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cups by Brew Type',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 12),
                    ...stats.cupsByBrewType.entries.map((entry) {
                      final total = stats.totalCupsMade;
                      final percentage =
                          total > 0 ? (entry.value / total * 100) : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(entry.key),
                            ),
                            Expanded(
                              flex: 7,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: AppTheme.accentCream,
                                      color: AppTheme.primaryBrown,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Settings section
          Text('Settings', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Rating Scale'),
                  subtitle: Text(_getRatingScaleName(user.ratingScale)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRatingScaleDialog(context, ref, user.ratingScale),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default View'),
                  subtitle: Text(_getViewPreferenceName(user.viewPreference)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showViewPreferenceDialog(context, ref, user.viewPreference),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.coffee_maker),
                  title: const Text('My Equipment'),
                  subtitle: Text(hasEquipment ? 'Manage brewing equipment' : 'Add equipment setups'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EquipmentScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Drink Recipe Book'),
                  subtitle: Text(ref.watch(hasDrinkRecipesProvider)
                      ? 'View and manage your drink recipes'
                      : 'No saved recipes yet'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DrinkRecipeBookScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account section
          if (!user.isPaid) ...[
            Text('Upgrade', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 12),
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: AppStyles.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text('Get access to:'),
                    const SizedBox(height: 8),
                    _buildBenefit('☁️ Cloud backup across devices'),
                    _buildBenefit('🌐 Access on web'),
                    _buildBenefit('🔗 Share recipes via QR codes'),
                    _buildBenefit('📱 Multi-device sync'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showUpgradeDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Upgrade Now'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text('Account', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user.email ?? 'Not set'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Manage Subscription'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implement subscription management
                      showError(context, 'Subscription management coming soon');
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Clear Data Button (for testing/development)
          Center(
            child: TextButton.icon(
              onPressed: _handleClearDataPress,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: Text(
                _clearDataPressCount > 0
                    ? 'Clear Data (${4 - _clearDataPressCount} more)'
                    : 'Clear Data',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryBrown),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.statValue),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.statLabel),
      ],
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text),
    );
  }

  String _getRatingScaleName(RatingScale scale) {
    switch (scale) {
      case RatingScale.oneToFive:
        return '1-5 Stars';
      case RatingScale.oneToTen:
        return '1-10 Scale';
      case RatingScale.oneToHundred:
        return '1-100 Scale';
    }
  }

  String _getViewPreferenceName(ViewPreference pref) {
    switch (pref) {
      case ViewPreference.grid:
        return 'Grid';
      case ViewPreference.list:
        return 'List';
      case ViewPreference.rolodex:
        return 'Rolodex';
    }
  }

  void _showRatingScaleDialog(BuildContext context, WidgetRef ref, RatingScale current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rating Scale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RatingScale.values.map((scale) {
            return RadioListTile<RatingScale>(
              title: Text(_getRatingScaleName(scale)),
              value: scale,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(userProfileProvider.notifier).updateRatingScale(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showViewPreferenceDialog(BuildContext context, WidgetRef ref, ViewPreference current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default View'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ViewPreference.values.map((pref) {
            return RadioListTile<ViewPreference>(
              title: Text(_getViewPreferenceName(pref)),
              value: pref,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(userProfileProvider.notifier).updateViewPreference(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Premium features are not yet implemented. '
          'Firebase configuration is required to enable cloud sync and sharing.',
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

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String? currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(userProfileProvider.notifier).updateUsername(newName);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditBioDialog(BuildContext context, WidgetRef ref, String? currentBio) {
    final controller = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bio'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Short bio (max 25 characters)',
            helperText: 'Keep it short and sweet!',
          ),
          autofocus: true,
          maxLength: 25,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newBio = controller.text.trim();
              ref.read(userProfileProvider.notifier).updateBio(newBio.isEmpty ? null : newBio);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProfilePictureOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final photoService = PhotoService();
                try {
                  final photoPath = await photoService.takePhoto();
                  if (photoPath != null) {
                    ref.read(userProfileProvider.notifier).updateProfilePicture(photoPath);
                  }
                } catch (e) {
                  if (context.mounted) {
                    showError(context, 'Failed to take photo: $e');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final photoService = PhotoService();
                try {
                  final photoPath = await photoService.pickPhoto();
                  if (photoPath != null) {
                    ref.read(userProfileProvider.notifier).updateProfilePicture(photoPath);
                  }
                } catch (e) {
                  if (context.mounted) {
                    showError(context, 'Failed to pick photo: $e');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                ref.read(userProfileProvider.notifier).updateProfilePicture(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _recalculateStats(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Recalculating statistics...'),
          ],
        ),
      ),
    );

    try {
      await ref.read(userProfileProvider.notifier).recalculateStats();
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistics recalculated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        showError(context, 'Failed to recalculate stats: $e');
      }
    }
  }

  void _handleClearDataPress() {
    setState(() {
      _clearDataPressCount++;
    });

    if (_clearDataPressCount >= 4) {
      // Reset counter
      _clearDataPressCount = 0;

      // Show confirmation dialog
      _showClearDataConfirmation();
    } else {
      // Reset counter after 3 seconds if they don't complete the sequence
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _clearDataPressCount = 0;
          });
        }
      });
    }
  }

  void _showClearDataConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ALL data?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('This will permanently delete:'),
            SizedBox(height: 8),
            Text('• All coffee bags'),
            Text('• All cups and tasting notes'),
            Text('• All drink recipes'),
            Text('• All equipment setups'),
            Text('• All user data'),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Clearing all data...'),
          ],
        ),
      ),
    );

    try {
      // Clear all data from database
      await DatabaseService().clearAllData();

      if (mounted) {
        // Invalidate all Riverpod providers to force reload from database
        ref.invalidate(userProfileProvider);
        ref.invalidate(bagsProvider);
        ref.invalidate(cupsNotifierProvider);
        ref.invalidate(equipmentProvider);
        ref.invalidate(drinkRecipesProvider);

        Navigator.pop(context); // Close progress dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared. Starting fresh!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the screen by rebuilding
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        showError(context, 'Failed to clear data: $e');
      }
    }
  }
}
