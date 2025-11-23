import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/equipment_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import 'equipment_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryBrown,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.username ?? 'Coffee Enthusiast',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
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
          Text('Statistics', style: AppTextStyles.sectionHeader),
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
                  leading: const Icon(Icons.feedback),
                  title: const Text('Send Feedback'),
                  subtitle: const Text('Share your thoughts with us'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeedbackDialog(context, user),
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

  void _showFeedbackDialog(BuildContext context, dynamic user) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We value your feedback! Let us know what you think about BrewLog.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final feedback = feedbackController.text.trim();
              if (feedback.isEmpty) {
                showError(context, 'Please enter your feedback');
                return;
              }

              Navigator.pop(context);
              await _sendFeedback(context, feedback, user);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback(BuildContext context, String feedback, dynamic user) async {
    try {
      // Submit feedback to Firebase Firestore
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.id,
        'username': user.username ?? 'Unknown User',
        'email': user.email,
        'isPremium': user.isPaid,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
        'platform': 'mobile',
      });

      if (context.mounted) {
        showSuccess(context, 'Thank you for your feedback!');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Failed to submit feedback. Please try again.');
      }
    }
  }
}
