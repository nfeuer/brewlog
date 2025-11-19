import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/coffee_bag.dart';
import '../models/cup.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../providers/user_provider.dart';
import '../providers/equipment_provider.dart';
import '../services/photo_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import '../widgets/rating_input.dart';
import 'equipment_form_screen.dart';

class CupCardScreen extends ConsumerStatefulWidget {
  final String? bagId;
  final String? cupId;
  final bool isNewBag;

  const CupCardScreen({
    super.key,
    this.bagId,
    this.cupId,
    this.isNewBag = false,
  });

  @override
  ConsumerState<CupCardScreen> createState() => _CupCardScreenState();
}

class _CupCardScreenState extends ConsumerState<CupCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = PhotoService();

  // Bag info controllers
  final _coffeeNameController = TextEditingController();
  final _roasterController = TextEditingController();
  final _customTitleController = TextEditingController();
  final _farmerController = TextEditingController();
  final _varietyController = TextEditingController();
  final _elevationController = TextEditingController();
  final _beanAromaController = TextEditingController();

  // Cup info controllers
  final _grindLevelController = TextEditingController();
  final _waterTempController = TextEditingController();
  final _gramsUsedController = TextEditingController();
  final _finalVolumeController = TextEditingController();
  final _brewTimeController = TextEditingController();
  final _bloomTimeController = TextEditingController();
  final _tastingNotesController = TextEditingController();

  String? _selectedBrewType;
  String? _selectedEquipmentId;
  double? _rating;
  List<String> _selectedFlavorTags = [];
  List<String> _photoPaths = [];
  bool _isBest = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.cupId != null) {
      // Load existing cup
      final cup = ref.read(cupProvider(widget.cupId!));
      if (cup != null) {
        // Get user's current rating scale to load the rating in correct scale
        final ratingScale = ref.read(ratingScaleProvider);

        _selectedBrewType = cup.brewType;
        _selectedEquipmentId = cup.equipmentSetupId;
        _grindLevelController.text = cup.grindLevel ?? '';
        _waterTempController.text = cup.waterTempCelsius?.toString() ?? '';
        _gramsUsedController.text = cup.gramsUsed?.toString() ?? '';
        _finalVolumeController.text = cup.finalVolumeMl?.toString() ?? '';
        _brewTimeController.text = cup.brewTimeSeconds?.toString() ?? '';
        _bloomTimeController.text = cup.bloomTimeSeconds?.toString() ?? '';
        // Load rating in user's current preferred scale
        _rating = cup.getRating(ratingScale);
        _tastingNotesController.text = cup.tastingNotes ?? '';
        _selectedFlavorTags = List.from(cup.flavorTags);
        _photoPaths = List.from(cup.photoPaths);
        _isBest = cup.isBest;

        // Load bag info
        final bag = ref.read(bagProvider(cup.bagId));
        if (bag != null) {
          _customTitleController.text = bag.customTitle;
          _coffeeNameController.text = bag.coffeeName;
          _roasterController.text = bag.roaster;
          _farmerController.text = bag.farmer ?? '';
          _varietyController.text = bag.variety ?? '';
          _elevationController.text = bag.elevation ?? '';
          _beanAromaController.text = bag.beanAroma ?? '';
        }
      }
    } else if (widget.bagId != null) {
      // Load bag info for new cup
      final bag = ref.read(bagProvider(widget.bagId!));
      if (bag != null) {
        _customTitleController.text = bag.customTitle;
        _coffeeNameController.text = bag.coffeeName;
        _roasterController.text = bag.roaster;
        _farmerController.text = bag.farmer ?? '';
        _varietyController.text = bag.variety ?? '';
        _elevationController.text = bag.elevation ?? '';
        _beanAromaController.text = bag.beanAroma ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingScale = ref.watch(ratingScaleProvider);
    final allBrewTypes = ref.watch(allBrewTypesProvider);
    final allEquipment = ref.watch(equipmentProvider);
    final fieldVisibility = ref.watch(cupFieldVisibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewBag
            ? 'New Coffee Bag'
            : widget.cupId != null
                ? 'Edit Cup'
                : 'New Cup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Configure visible fields',
            onPressed: () => _showFieldVisibilityDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCup,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppStyles.screenPadding,
          children: [
            // Bag Info Section (expandable if not new bag)
            _buildSection(
              'Coffee Bag Info',
              [
                TextFormField(
                  controller: _customTitleController,
                  decoration: const InputDecoration(labelText: 'Custom Title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _coffeeNameController,
                  decoration: const InputDecoration(labelText: 'Coffee Name *'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roasterController,
                  decoration: const InputDecoration(labelText: 'Roaster *'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                if (fieldVisibility['farmer'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _farmerController,
                    decoration: const InputDecoration(labelText: 'Farmer'),
                  ),
                ],
                if (fieldVisibility['variety'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _varietyController,
                    decoration: const InputDecoration(labelText: 'Variety'),
                  ),
                ],
                if (fieldVisibility['elevation'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _elevationController,
                    decoration: const InputDecoration(labelText: 'Elevation'),
                  ),
                ],
                if (fieldVisibility['beanAroma'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beanAromaController,
                    decoration: const InputDecoration(labelText: 'Bean Aroma'),
                    maxLines: 2,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Brew Parameters Section
            _buildSection(
              'Brew Parameters',
              [
                DropdownButtonFormField<String>(
                  value: _selectedBrewType,
                  decoration: const InputDecoration(labelText: 'Brew Type *'),
                  items: allBrewTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedBrewType = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                if (fieldVisibility['equipment'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedEquipmentId,
                          decoration: const InputDecoration(
                            labelText: 'Equipment Setup',
                            hintText: 'Optional',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None'),
                            ),
                            ...allEquipment.map((setup) => DropdownMenuItem(
                                  value: setup.id,
                                  child: Text(setup.name),
                                )),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedEquipmentId = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add Equipment Setup',
                        onPressed: () async {
                          final user = ref.read(userProfileProvider);
                          if (user == null) return;

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentFormScreen(userId: user.id),
                            ),
                          );
                          if (result == true) {
                            // Refresh the equipment list and select the newly created one
                            final newEquipment = ref.read(equipmentProvider);
                            if (newEquipment.isNotEmpty) {
                              setState(() {
                                _selectedEquipmentId = newEquipment.first.id;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
                if (fieldVisibility['grindLevel'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _grindLevelController,
                    decoration: const InputDecoration(labelText: 'Grind Level'),
                  ),
                ],
                if (fieldVisibility['waterTemp'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _waterTempController,
                    decoration:
                        const InputDecoration(labelText: 'Water Temp (°C)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (fieldVisibility['gramsUsed'] == true ||
                    fieldVisibility['finalVolume'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (fieldVisibility['gramsUsed'] == true)
                        Expanded(
                          child: TextFormField(
                            controller: _gramsUsedController,
                            decoration:
                                const InputDecoration(labelText: 'Grams Used'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      if (fieldVisibility['gramsUsed'] == true &&
                          fieldVisibility['finalVolume'] == true)
                        const SizedBox(width: 12),
                      if (fieldVisibility['finalVolume'] == true)
                        Expanded(
                          child: TextFormField(
                            controller: _finalVolumeController,
                            decoration:
                                const InputDecoration(labelText: 'Final Volume (ml)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                    ],
                  ),
                ],
                if (fieldVisibility['brewTime'] == true ||
                    fieldVisibility['bloomTime'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (fieldVisibility['brewTime'] == true)
                        Expanded(
                          child: TextFormField(
                            controller: _brewTimeController,
                            decoration: const InputDecoration(
                                labelText: 'Brew Time (sec)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      if (fieldVisibility['brewTime'] == true &&
                          fieldVisibility['bloomTime'] == true)
                        const SizedBox(width: 12),
                      if (fieldVisibility['bloomTime'] == true)
                        Expanded(
                          child: TextFormField(
                            controller: _bloomTimeController,
                            decoration: const InputDecoration(
                                labelText: 'Bloom Time (sec)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),

            if (fieldVisibility['rating'] == true) ...[
              const SizedBox(height: 24),
              // Rating Section
              _buildSection(
                'Rating',
                [
                  Center(
                    child: RatingInput(
                      scale: ratingScale,
                      value: _rating,
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                  ),
                ],
              ),
            ],

            if (fieldVisibility['tastingNotes'] == true ||
                fieldVisibility['flavorTags'] == true) ...[
              const SizedBox(height: 24),
              // Tasting Notes Section
              _buildSection(
                'Tasting Notes',
                [
                  if (fieldVisibility['tastingNotes'] == true)
                    TextFormField(
                      controller: _tastingNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Describe the taste, aroma, and experience...',
                      ),
                      maxLines: 4,
                    ),
                  if (fieldVisibility['flavorTags'] == true) ...[
                    if (fieldVisibility['tastingNotes'] == true)
                      const SizedBox(height: 16),
                    Text('Flavor Tags', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: defaultFlavorTags.map((tag) {
                        final isSelected = _selectedFlavorTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFlavorTags.add(tag);
                              } else {
                                _selectedFlavorTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ],

            if (fieldVisibility['photos'] == true) ...[
              const SizedBox(height: 24),
              // Photos Section
              _buildSection(
                'Photos',
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._photoPaths.map((path) => _buildPhotoThumbnail(path)),
                      _buildAddPhotoButton(),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Best Recipe Toggle
            if (fieldVisibility['bestRecipe'] == true)
              CheckboxListTile(
                title: const Text('Mark as Best Recipe'),
                subtitle: const Text('This will be your reference cup for this bag'),
                value: _isBest,
                onChanged: (value) => setState(() => _isBest = value ?? false),
              ),

            const SizedBox(height: 24),

            // Delete button (if editing)
            if (widget.cupId != null) ...[
              ElevatedButton.icon(
                onPressed: _deleteCup,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Cup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionHeader),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildPhotoThumbnail(String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: () => setState(() => _photoPaths.remove(path)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _addPhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.accentCream,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add_a_photo, color: AppTheme.primaryBrown),
      ),
    );
  }

  void _addPhoto() async {
    // Show dialog to choose between camera and gallery
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photo'),
        content: const Text('Choose photo source'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    String? path;
    if (source == 'camera') {
      path = await _photoService.takePhoto();
    } else {
      path = await _photoService.pickPhoto();
    }

    if (path != null) {
      setState(() => _photoPaths.add(path!));
    }
  }

  void _showFieldVisibilityDialog(BuildContext context) async {
    final currentVisibility = ref.read(cupFieldVisibilityProvider);
    final tempVisibility = Map<String, bool>.from(currentVisibility);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Group fields by section
          final fieldsBySection = <String, List<CupFieldDefinition>>{};
          for (final field in cupFields) {
            fieldsBySection.putIfAbsent(field.section, () => []);
            fieldsBySection[field.section]!.add(field);
          }

          return AlertDialog(
            title: const Text('Configure Visible Fields'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: fieldsBySection.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          entry.key,
                          style: AppTextStyles.sectionHeader,
                        ),
                      ),
                      ...entry.value.map((field) {
                        return CheckboxListTile(
                          title: Text(field.displayName),
                          value: tempVisibility[field.key] ?? true,
                          onChanged: (value) {
                            setDialogState(() {
                              tempVisibility[field.key] = value ?? true;
                            });
                          },
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Save preferences
                  await ref
                      .read(userProfileProvider.notifier)
                      .updateCupFieldVisibility(tempVisibility);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSuccess(context, 'Field visibility updated');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveCup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrewType == null) {
      showError(context, 'Please select a brew type');
      return;
    }

    final user = ref.read(userProfileProvider);
    if (user == null) return;

    final uuid = const Uuid();

    // Determine bag ID
    String finalBagId;

    if (widget.cupId != null) {
      // Editing existing cup - get bag ID from the cup
      final existingCup = ref.read(cupProvider(widget.cupId!));
      if (existingCup == null) {
        if (mounted) showError(context, 'Cup not found');
        return;
      }
      finalBagId = existingCup.bagId;
    } else if (widget.bagId != null) {
      // Creating new cup for existing bag
      finalBagId = widget.bagId!;
    } else if (widget.isNewBag) {
      // Creating new bag with first cup
      finalBagId = uuid.v4();
      final bag = CoffeeBag(
        id: finalBagId,
        userId: user.id,
        customTitle: _customTitleController.text.isEmpty
            ? _coffeeNameController.text
            : _customTitleController.text,
        coffeeName: _coffeeNameController.text,
        roaster: _roasterController.text,
        farmer: _farmerController.text.isEmpty ? null : _farmerController.text,
        variety: _varietyController.text.isEmpty ? null : _varietyController.text,
        elevation: _elevationController.text.isEmpty ? null : _elevationController.text,
        beanAroma: _beanAromaController.text.isEmpty ? null : _beanAromaController.text,
        openDate: DateTime.now(),
      );

      await ref.read(bagsProvider.notifier).createBag(bag);
    } else {
      // Should not happen
      if (mounted) showError(context, 'Invalid state');
      return;
    }

    // Create or update cup
    final cupId = widget.cupId ?? uuid.v4();
    final cup = Cup(
      id: cupId,
      bagId: finalBagId,
      userId: user.id,
      brewType: _selectedBrewType!,
      grindLevel: _grindLevelController.text.isEmpty ? null : _grindLevelController.text,
      waterTempCelsius: _waterTempController.text.isEmpty
          ? null
          : double.tryParse(_waterTempController.text),
      gramsUsed: _gramsUsedController.text.isEmpty
          ? null
          : double.tryParse(_gramsUsedController.text),
      finalVolumeMl: _finalVolumeController.text.isEmpty
          ? null
          : double.tryParse(_finalVolumeController.text),
      brewTimeSeconds: _brewTimeController.text.isEmpty
          ? null
          : int.tryParse(_brewTimeController.text),
      bloomTimeSeconds: _bloomTimeController.text.isEmpty
          ? null
          : int.tryParse(_bloomTimeController.text),
      tastingNotes: _tastingNotesController.text.isEmpty
          ? null
          : _tastingNotesController.text,
      flavorTags: _selectedFlavorTags,
      photoPaths: _photoPaths,
      isBest: _isBest,
      equipmentSetupId: _selectedEquipmentId,
    );

    // Update rating
    if (_rating != null) {
      cup.updateRating(_rating!, ref.read(ratingScaleProvider));
    }

    // Save cup
    final cupsNotifier = ref.read(cupsNotifierProvider);
    if (widget.cupId != null) {
      await cupsNotifier.updateCup(cup);
    } else {
      await cupsNotifier.createCup(cup);
    }

    if (mounted) {
      showSuccess(context, 'Cup saved!');
      Navigator.pop(context);
    }
  }

  void _deleteCup() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Cup',
      message: 'Are you sure you want to delete this cup?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed && widget.cupId != null) {
      final cupsNotifier = ref.read(cupsNotifierProvider);
      await cupsNotifier.deleteCup(widget.cupId!);

      if (mounted) {
        showSuccess(context, 'Cup deleted');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _coffeeNameController.dispose();
    _roasterController.dispose();
    _customTitleController.dispose();
    _farmerController.dispose();
    _varietyController.dispose();
    _elevationController.dispose();
    _beanAromaController.dispose();
    _grindLevelController.dispose();
    _waterTempController.dispose();
    _gramsUsedController.dispose();
    _finalVolumeController.dispose();
    _brewTimeController.dispose();
    _bloomTimeController.dispose();
    _tastingNotesController.dispose();
    super.dispose();
  }
}
