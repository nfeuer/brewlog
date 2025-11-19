import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_setup.dart';
import '../providers/equipment_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import 'equipment_form_screen.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipment = ref.watch(equipmentProvider);
    final user = ref.watch(userProfileProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showEquipmentGuide(context),
            tooltip: 'Equipment Guide',
          ),
        ],
      ),
      body: equipment.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: AppStyles.screenPadding,
              itemCount: equipment.length,
              itemBuilder: (context, index) {
                final setup = equipment[index];
                return _buildEquipmentCard(context, ref, setup);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewEquipment(context, user.id),
        icon: const Icon(Icons.add),
        label: const Text('New Setup'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppStyles.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.coffee_maker_outlined,
              size: 64,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Equipment Yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your brewing equipment to help others replicate your recipes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGray,
                  ),
            ),
            const SizedBox(height: 24),
            const Text(
              '💡 Tip: When you share a cup with your equipment, '
              'others can see what tools you used and adapt the recipe to their setup.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    WidgetRef ref,
    EquipmentSetup setup,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editEquipment(context, setup),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      setup.name,
                      style: AppTextStyles.cardTitle,
                    ),
                  ),
                  if (setup.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Equipment details
              if (setup.grinderBrand != null || setup.grinderModel != null)
                _buildEquipmentRow(
                  Icons.blender,
                  'Grinder',
                  setup.grinderDisplayName,
                ),
              if (setup.brewerBrand != null || setup.brewerModel != null)
                _buildEquipmentRow(
                  Icons.coffee_maker,
                  'Brewer',
                  setup.brewerDisplayName,
                ),
              if (setup.kettleBrand != null)
                _buildEquipmentRow(
                  Icons.hot_tub,
                  'Kettle',
                  setup.kettleBrand!,
                ),
              if (setup.scaleBrand != null)
                _buildEquipmentRow(
                  Icons.scale,
                  'Scale',
                  '${setup.scaleBrand}${setup.scaleAccuracy != null ? " (±${setup.scaleAccuracy}g)" : ""}',
                ),
              if (setup.waterType != null)
                _buildEquipmentRow(
                  Icons.water_drop,
                  'Water',
                  setup.waterType!,
                ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!setup.isDefault)
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(equipmentProvider.notifier).setAsDefault(setup.id),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Set as Default'),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEquipment(context, ref, setup),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textGray),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _createNewEquipment(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentFormScreen(userId: userId),
      ),
    );
  }

  void _editEquipment(BuildContext context, EquipmentSetup setup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentFormScreen(
          userId: setup.userId,
          equipment: setup,
        ),
      ),
    );
  }

  void _deleteEquipment(
    BuildContext context,
    WidgetRef ref,
    EquipmentSetup setup,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Equipment Setup',
      message:
          'Are you sure you want to delete "${setup.name}"? This won\'t affect existing cups that used this equipment.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      await ref.read(equipmentProvider.notifier).deleteEquipment(setup.id);
      if (context.mounted) {
        showSuccess(context, 'Equipment deleted');
      }
    }
  }

  void _showEquipmentGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Equipment Setup Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Why track equipment?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Help others replicate your recipes\n'
                '• Compare results across different setups\n'
                '• Share equipment details with each cup',
              ),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Create different setups for home/office/travel\n'
                '• Mark one as default for quick selection\n'
                '• Include grinder settings in cup notes\n'
                '• Share adaptation tips for different equipment',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
