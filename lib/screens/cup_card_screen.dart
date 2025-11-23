import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/coffee_bag.dart';
import '../models/cup.dart';
import '../models/drink_recipe.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../providers/user_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/drink_recipes_provider.dart';
import '../services/photo_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import '../widgets/rating_input.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/temperature_dial.dart';
import '../widgets/pour_schedule_timer.dart';
import '../widgets/grind_size_wheel.dart';
import 'equipment_form_screen.dart';
import 'share_cup_screen.dart';

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
  final _priceController = TextEditingController();
  final _bagSizeController = TextEditingController();
  final _restDaysController = TextEditingController();

  // Bag date fields
  DateTime? _datePurchased;
  DateTime? _roastDate;
  DateTime? _openDate;

  // Cup info controllers
  final _grindLevelController = TextEditingController();
  final _waterTempController = TextEditingController();
  final _gramsUsedController = TextEditingController();
  final _finalVolumeController = TextEditingController();
  final _brewTimeController = TextEditingController();
  final _brewTimeFormattedController = TextEditingController();
  final _bloomTimeController = TextEditingController();
  final _tastingNotesController = TextEditingController();

  // Grinder settings (can override equipment settings)
  double? _grinderMinSetting;
  double? _grinderMaxSetting;
  double? _grinderStepSize;

  // Advanced brewing parameter controllers
  final _preInfusionTimeController = TextEditingController();
  final _pressureBarsController = TextEditingController();
  final _yieldGramsController = TextEditingController();
  final _bloomAmountController = TextEditingController();
  final _pourScheduleController = TextEditingController();
  final _tdsController = TextEditingController();
  final _extractionYieldController = TextEditingController();

  // Environmental condition controllers
  final _roomTempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _altitudeController = TextEditingController();

  // SCA cupping score values (using sliders, 1-10 scale)
  double? _cuppingFragrance;
  double? _cuppingAroma;
  double? _cuppingFlavor;
  double? _cuppingAftertaste;
  double? _cuppingAcidity;
  double? _cuppingBody;
  double? _cuppingBalance;
  double? _cuppingSweetness;
  double? _cuppingCleanCup;
  double? _cuppingUniformity;
  final _cuppingDefectsController = TextEditingController();

  String? _selectedBrewType;
  String? _selectedEquipmentId;
  String? _timeOfDay;
  double? _rating;
  List<String> _selectedFlavorTags = [];
  List<String> _photoPaths = [];
  bool _showScaCuppingFields = false;
  bool _isBest = false;
  List<PourEntry> _pourEntries = [];
  bool _usePourTimer = false;
  Map<String, bool> _currentFieldVisibility = {};

  // Drink recipe fields
  String? _selectedDrinkRecipeId;
  final _drinkNameController = TextEditingController();
  String? _drinkBaseType;
  String? _drinkEspressoShot;
  String? _drinkMilkType;
  final _drinkMilkAmountController = TextEditingController();
  bool _drinkIce = false;
  List<String> _drinkSyrups = [];
  List<String> _drinkSweeteners = [];
  List<String> _drinkOtherAdditions = [];
  final _drinkInstructionsController = TextEditingController();
  bool _showDrinkRecipeSection = false;
  bool _showDrinkRecipeDetails = false;

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

        // Load per-cup field visibility or use defaults
        _currentFieldVisibility = cup.fieldVisibility != null
            ? Map<String, bool>.from(cup.fieldVisibility!)
            : Map<String, bool>.from(ref.read(cupFieldVisibilityProvider));

        _selectedBrewType = cup.brewType;
        _selectedEquipmentId = cup.equipmentSetupId;
        _grindLevelController.text = cup.grindLevel ?? '';
        _waterTempController.text = cup.waterTempCelsius?.toString() ?? '';
        _gramsUsedController.text = cup.gramsUsed?.toString() ?? '';
        _finalVolumeController.text = cup.finalVolumeMl?.toString() ?? '';
        _brewTimeController.text = cup.brewTimeSeconds?.toString() ?? '';
        _brewTimeFormattedController.text = _formatSecondsToMinSec(cup.brewTimeSeconds?.toString() ?? '');
        _bloomTimeController.text = cup.bloomTimeSeconds?.toString() ?? '';

        // Load advanced brewing parameters
        _preInfusionTimeController.text = cup.preInfusionTimeSeconds?.toString() ?? '';
        _pressureBarsController.text = cup.pressureBars?.toString() ?? '';
        _yieldGramsController.text = cup.yieldGrams?.toString() ?? '';
        _bloomAmountController.text = cup.bloomAmountGrams?.toString() ?? '';
        _pourScheduleController.text = cup.pourSchedule ?? '';
        _parsePourSchedule(cup.pourSchedule);
        _tdsController.text = cup.tds?.toString() ?? '';
        _extractionYieldController.text = cup.extractionYield?.toString() ?? '';

        // Load environmental conditions
        _roomTempController.text = cup.roomTempCelsius?.toString() ?? '';
        _humidityController.text = cup.humidity?.toString() ?? '';
        _altitudeController.text = cup.altitudeMeters?.toString() ?? '';
        _timeOfDay = cup.timeOfDay;

        // Load SCA cupping scores
        _cuppingFragrance = cup.cuppingFragrance;
        _cuppingAroma = cup.cuppingAroma;
        _cuppingFlavor = cup.cuppingFlavor;
        _cuppingAftertaste = cup.cuppingAftertaste;
        _cuppingAcidity = cup.cuppingAcidity;
        _cuppingBody = cup.cuppingBody;
        _cuppingBalance = cup.cuppingBalance;
        _cuppingSweetness = cup.cuppingSweetness;
        _cuppingCleanCup = cup.cuppingCleanCup;
        _cuppingUniformity = cup.cuppingUniformity;
        _cuppingDefectsController.text = cup.cuppingDefects ?? '';

        // Show SCA section if any scores are present
        _showScaCuppingFields = cup.cuppingFragrance != null ||
            cup.cuppingAroma != null ||
            cup.cuppingFlavor != null ||
            cup.cuppingAftertaste != null ||
            cup.cuppingAcidity != null ||
            cup.cuppingBody != null ||
            cup.cuppingBalance != null ||
            cup.cuppingSweetness != null ||
            cup.cuppingCleanCup != null ||
            cup.cuppingUniformity != null ||
            (cup.cuppingDefects != null && cup.cuppingDefects!.isNotEmpty);

        // Load rating in user's current preferred scale
        _rating = cup.getRating(ratingScale);
        _tastingNotesController.text = cup.tastingNotes ?? '';
        _selectedFlavorTags = List.from(cup.flavorTags);
        _photoPaths = List.from(cup.photoPaths);
        _isBest = cup.isBest;

        // Load drink recipe if present
        if (cup.drinkRecipeId != null) {
          _selectedDrinkRecipeId = cup.drinkRecipeId;
          final recipe = ref.read(drinkRecipeByIdProvider(cup.drinkRecipeId!));
          if (recipe != null) {
            _loadDrinkRecipe(recipe);
            _showDrinkRecipeSection = true;
          }
        }

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
          _priceController.text = bag.price?.toString() ?? '';
          _bagSizeController.text = bag.bagSizeGrams?.toString() ?? '';
          _restDaysController.text = bag.recommendedRestDays?.toString() ?? '';
          _datePurchased = bag.datePurchased;
          _roastDate = bag.roastDate;
          _openDate = bag.openDate;
        }
      }
    } else {
      // Creating a new cup - use default field visibility
      _currentFieldVisibility = Map<String, bool>.from(ref.read(cupFieldVisibilityProvider));

      if (widget.bagId != null) {
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
          _priceController.text = bag.price?.toString() ?? '';
          _bagSizeController.text = bag.bagSizeGrams?.toString() ?? '';
          _restDaysController.text = bag.recommendedRestDays?.toString() ?? '';
          _datePurchased = bag.datePurchased;
          _roastDate = bag.roastDate;
          _openDate = bag.openDate;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingScale = ref.watch(ratingScaleProvider);
    final allBrewTypes = ref.watch(allBrewTypesProvider);
    final allEquipment = ref.watch(equipmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewBag
            ? 'New Coffee Bag'
            : widget.cupId != null
                ? 'Edit Cup'
                : 'New Cup'),
        actions: [
          // Share button (only shown when editing existing cup)
          if (widget.cupId != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share tasting notes',
              onPressed: () {
                // Get the current cup from state
                final currentCup = ref.read(cupProvider(widget.cupId!));
                if (currentCup == null) {
                  showError(context, 'Cup not found');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShareCupScreen(cup: currentCup),
                  ),
                );
              },
            ),
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
            // Bag Info Section (only show when creating a new bag or editing existing cup)
            if (widget.bagId == null || widget.cupId != null)
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
                if (_currentFieldVisibility['farmer'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _farmerController,
                    decoration: const InputDecoration(labelText: 'Farmer'),
                  ),
                ],
                if (_currentFieldVisibility['variety'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _varietyController,
                    decoration: const InputDecoration(labelText: 'Variety'),
                  ),
                ],
                if (_currentFieldVisibility['elevation'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _elevationController,
                    decoration: const InputDecoration(labelText: 'Elevation'),
                  ),
                ],
                if (_currentFieldVisibility['beanAroma'] == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beanAromaController,
                    decoration: const InputDecoration(labelText: 'Bean Aroma'),
                    maxLines: 2,
                  ),
                ],
                // Additional bag fields (only shown when creating new bag)
                if (widget.isNewBag) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bagSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Bag Size',
                      suffixText: 'g',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _restDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Recommended Rest Days',
                      suffixText: 'days',
                      hintText: 'Days to rest after roasting',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _datePurchased ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _datePurchased = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date Purchased',
                        suffixIcon: _datePurchased != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _datePurchased = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _datePurchased != null
                            ? '${_datePurchased!.year}-${_datePurchased!.month.toString().padLeft(2, '0')}-${_datePurchased!.day.toString().padLeft(2, '0')}'
                            : 'Select date',
                        style: _datePurchased != null
                            ? null
                            : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _roastDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _roastDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Roast Date',
                        suffixIcon: _roastDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _roastDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _roastDate != null
                            ? '${_roastDate!.year}-${_roastDate!.month.toString().padLeft(2, '0')}-${_roastDate!.day.toString().padLeft(2, '0')}'
                            : 'Select date',
                        style: _roastDate != null
                            ? null
                            : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _openDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _openDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Open Date',
                        suffixIcon: _openDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _openDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _openDate != null
                            ? '${_openDate!.year}-${_openDate!.month.toString().padLeft(2, '0')}-${_openDate!.day.toString().padLeft(2, '0')}'
                            : 'Select date',
                        style: _openDate != null
                            ? null
                            : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                ],
              ],
              ),

            if (widget.bagId == null || widget.cupId != null) const SizedBox(height: 24),

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
                if (_currentFieldVisibility['equipment'] == true) ...[
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
                  // Equipment details expand/collapse
                  if (_selectedEquipmentId != null) ...[
                    const SizedBox(height: 12),
                    ExpansionTile(
                      title: const Text('Equipment Details'),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(left: 16, bottom: 12),
                      children: [
                        Builder(
                          builder: (context) {
                            final equipment = ref.watch(equipmentByIdProvider(_selectedEquipmentId!));
                            if (equipment == null) {
                              return const Text('Equipment not found');
                            }

                            final details = <Widget>[];

                            // Only show fields that have values
                            if (equipment.grinderBrand != null || equipment.grinderModel != null) {
                              details.add(_buildEquipmentDetailRow(
                                Icons.blender,
                                'Grinder',
                                equipment.grinderDisplayName,
                              ));
                            }
                            if (equipment.brewerBrand != null || equipment.brewerModel != null) {
                              details.add(_buildEquipmentDetailRow(
                                Icons.coffee_maker,
                                'Brewer',
                                equipment.brewerDisplayName,
                              ));
                            }
                            if (equipment.kettleBrand != null) {
                              details.add(_buildEquipmentDetailRow(
                                Icons.hot_tub,
                                'Kettle',
                                equipment.kettleBrand!,
                              ));
                            }
                            if (equipment.scaleBrand != null) {
                              details.add(_buildEquipmentDetailRow(
                                Icons.scale,
                                'Scale',
                                '${equipment.scaleBrand}${equipment.scaleAccuracy != null ? " (±${equipment.scaleAccuracy}g)" : ""}',
                              ));
                            }
                            if (equipment.waterType != null) {
                              details.add(_buildEquipmentDetailRow(
                                Icons.water_drop,
                                'Water',
                                equipment.waterType!,
                              ));
                            }
                            if (equipment.filterType != null) {
                              details.add(_buildEquipmentDetailRow(
                                Icons.filter_alt,
                                'Filter',
                                equipment.filterType!,
                              ));
                            }

                            if (details.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'No equipment details available',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: details,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
                if (_currentFieldVisibility['grindLevel'] == true) ...[
                  const SizedBox(height: 24),
                  // Get grinder settings from selected equipment (if available)
                  Builder(
                    builder: (context) {
                      final equipment = _selectedEquipmentId != null
                          ? ref.watch(equipmentByIdProvider(_selectedEquipmentId!))
                          : null;

                      // Use override values if set, otherwise fall back to equipment settings
                      final minValue = _grinderMinSetting ?? equipment?.grinderMinSetting ?? 0.0;
                      final maxValue = _grinderMaxSetting ?? equipment?.grinderMaxSetting ?? 50.0;
                      final stepSize = _grinderStepSize ?? equipment?.grinderStepSize ?? 1.0;

                      return GrindSizeWheel(
                        initialValue: _grindLevelController.text.isEmpty
                            ? null
                            : double.tryParse(_grindLevelController.text),
                        onChanged: (value) {
                          setState(() {
                            _grindLevelController.text = value?.toStringAsFixed(
                              stepSize < 1 ? 2 : (stepSize == 1 ? 0 : 1),
                            ) ?? '';
                          });
                        },
                        minValue: minValue,
                        maxValue: maxValue,
                        stepSize: stepSize,
                        showRangeControls: true,
                        onMinValueChanged: (value) {
                          setState(() {
                            _grinderMinSetting = value;
                          });
                        },
                        onMaxValueChanged: (value) {
                          setState(() {
                            _grinderMaxSetting = value;
                          });
                        },
                        onStepSizeChanged: (value) {
                          setState(() {
                            _grinderStepSize = value;
                          });
                        },
                      );
                    },
                  ),
                ],
                if (_currentFieldVisibility['waterTemp'] == true) ...[
                  const SizedBox(height: 24),
                  TemperatureDial(
                    initialValue: _waterTempController.text.isEmpty
                        ? null
                        : double.tryParse(_waterTempController.text),
                    onChanged: (value) {
                      setState(() {
                        _waterTempController.text = value?.toStringAsFixed(1) ?? '';
                      });
                    },
                  ),
                ],
                if (_currentFieldVisibility['gramsUsed'] == true ||
                    _currentFieldVisibility['finalVolume'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_currentFieldVisibility['gramsUsed'] == true)
                        Expanded(
                          child: TextFormField(
                            controller: _gramsUsedController,
                            decoration:
                                const InputDecoration(labelText: 'Grams Used'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      if (_currentFieldVisibility['gramsUsed'] == true &&
                          _currentFieldVisibility['finalVolume'] == true)
                        const SizedBox(width: 12),
                      if (_currentFieldVisibility['finalVolume'] == true)
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
                if (_currentFieldVisibility['brewTime'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brewTimeController,
                          decoration: const InputDecoration(
                              labelText: 'Brew Time (sec)'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            // Auto-update minutes:seconds field
                            _brewTimeFormattedController.text = _formatSecondsToMinSec(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _brewTimeFormattedController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Time (mm:ss)',
                          ),
                          style: const TextStyle(color: AppTheme.textGray),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Advanced Brewing Parameters Section (brew-type specific)
            if (_shouldShowAdvancedBrewingParams()) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Advanced Brewing Parameters',
                [
                  // Espresso-specific fields
                  if (_isEspressoBrew()) ...[
                    if (_currentFieldVisibility['preInfusionTime'] == true) ...[
                      TextFormField(
                        controller: _preInfusionTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Pre-Infusion Time',
                          suffixText: 'sec',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_currentFieldVisibility['pressureBars'] == true) ...[
                      TextFormField(
                        controller: _pressureBarsController,
                        decoration: const InputDecoration(
                          labelText: 'Pressure',
                          suffixText: 'bars',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_currentFieldVisibility['yieldGrams'] == true) ...[
                      TextFormField(
                        controller: _yieldGramsController,
                        decoration: const InputDecoration(
                          labelText: 'Yield',
                          suffixText: 'g',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  // Pour over-specific fields
                  if (_isPourOverBrew()) ...[
                    if (_currentFieldVisibility['bloomAmount'] == true ||
                        _currentFieldVisibility['bloomTime'] == true) ...[
                      Row(
                        children: [
                          if (_currentFieldVisibility['bloomAmount'] == true)
                            Expanded(
                              child: TextFormField(
                                controller: _bloomAmountController,
                                decoration: const InputDecoration(
                                  labelText: 'Bloom Water Amount',
                                  suffixText: 'g',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          if (_currentFieldVisibility['bloomAmount'] == true &&
                              _currentFieldVisibility['bloomTime'] == true)
                            const SizedBox(width: 12),
                          if (_currentFieldVisibility['bloomTime'] == true)
                            Expanded(
                              child: TextFormField(
                                controller: _bloomTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'Bloom Time',
                                  suffixText: 'sec',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_currentFieldVisibility['pourSchedule'] == true) ...[
                      Row(
                        children: [
                          const Text('Pour Schedule'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _usePourTimer = !_usePourTimer;
                              });
                            },
                            icon: Icon(_usePourTimer ? Icons.timer : Icons.text_fields),
                            label: Text(_usePourTimer ? 'Use Text' : 'Use Timer'),
                          ),
                        ],
                      ),
                      if (_usePourTimer) ...[
                        PourScheduleTimer(
                          initialEntries: _pourEntries,
                          onStop: (entries, totalSeconds, finalVolume, bloomAmount) {
                            setState(() {
                              _pourEntries = entries;
                              _brewTimeController.text = totalSeconds.toString();
                              _pourScheduleController.text = _formatPourEntries(entries);

                              // Populate Final Volume with last entry
                              if (finalVolume != null) {
                                _finalVolumeController.text = finalVolume.toStringAsFixed(0);
                              }

                              // Populate Bloom Water Amount with first entry
                              if (bloomAmount != null) {
                                _bloomAmountController.text = bloomAmount.toStringAsFixed(0);
                              }
                            });
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _pourScheduleController,
                          decoration: const InputDecoration(
                            labelText: 'Pour Schedule (Text)',
                            hintText: 'e.g., 0:00-50g, 0:45-100g, 1:30-final',
                          ),
                          maxLines: 2,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ],
                  // TDS and Extraction (for all brew types, hidden by default)
                  if (_currentFieldVisibility['tds'] == true) ...[
                    TextFormField(
                      controller: _tdsController,
                      decoration: const InputDecoration(
                        labelText: 'TDS',
                        suffixText: '%',
                        hintText: 'Requires refractometer',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentFieldVisibility['extractionYield'] == true) ...[
                    TextFormField(
                      controller: _extractionYieldController,
                      decoration: const InputDecoration(
                        labelText: 'Extraction Yield',
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ],
              ),
            ],

            // Environmental Conditions Section
            if (_shouldShowEnvironmentalConditions()) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Environmental Conditions',
                [
                  if (_currentFieldVisibility['roomTemp'] == true) ...[
                    TextFormField(
                      controller: _roomTempController,
                      decoration: const InputDecoration(
                        labelText: 'Room Temperature',
                        suffixText: '°C',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentFieldVisibility['humidity'] == true) ...[
                    TextFormField(
                      controller: _humidityController,
                      decoration: const InputDecoration(
                        labelText: 'Humidity',
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentFieldVisibility['altitude'] == true) ...[
                    TextFormField(
                      controller: _altitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Altitude',
                        suffixText: 'm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentFieldVisibility['timeOfDay'] == true) ...[
                    DropdownButtonFormField<String>(
                      value: _timeOfDay,
                      decoration: const InputDecoration(labelText: 'Time of Day'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Not specified')),
                        ...timesOfDay.map((time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            )),
                      ],
                      onChanged: (value) => setState(() => _timeOfDay = value),
                    ),
                  ],
                ],
              ),
            ],


            // Drink Recipe Section (Collapsible)
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showDrinkRecipeSection = !_showDrinkRecipeSection;
                  });
                },
                icon: Icon(_showDrinkRecipeSection ? Icons.expand_less : Icons.local_cafe),
                label: Text(_showDrinkRecipeSection ? 'Hide Drink Recipe' : 'Make a Drink'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBrown,
                  side: const BorderSide(color: AppTheme.primaryBrown),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            if (_showDrinkRecipeSection) ...[
              const SizedBox(height: 16),
              _buildSection(
                'Drink Recipe',
                [
                  // Recipe selection dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedDrinkRecipeId,
                    decoration: const InputDecoration(
                      labelText: 'Select Saved Recipe',
                      hintText: 'Optional - choose a saved recipe',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...ref.watch(drinkRecipesProvider).map((recipe) => DropdownMenuItem(
                            value: recipe.id,
                            child: Text(recipe.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDrinkRecipeId = value;
                        if (value != null) {
                          final recipe = ref.read(drinkRecipeByIdProvider(value));
                          if (recipe != null) {
                            _loadDrinkRecipe(recipe);
                          }
                        } else {
                          // Clear fields
                          _drinkNameController.clear();
                          _drinkBaseType = null;
                          _drinkEspressoShot = null;
                          _drinkMilkType = null;
                          _drinkMilkAmountController.clear();
                          _drinkIce = false;
                          _drinkSyrups.clear();
                          _drinkSweeteners.clear();
                          _drinkOtherAdditions.clear();
                          _drinkInstructionsController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Drink name
                  TextFormField(
                    controller: _drinkNameController,
                    decoration: const InputDecoration(
                      labelText: 'Drink Name',
                      hintText: 'e.g., Vanilla Latte, Iced Coffee',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Base type (inherits from brew type or can be overridden)
                  DropdownButtonFormField<String>(
                    value: _drinkBaseType ?? _selectedBrewType,
                    decoration: InputDecoration(
                      labelText: 'Base Type',
                      hintText: _selectedBrewType != null ? 'Inherits from Brew Type: $_selectedBrewType' : 'Optional',
                    ),
                    items: [
                      if (_selectedBrewType != null)
                        DropdownMenuItem(
                          value: _selectedBrewType,
                          child: Text('$_selectedBrewType (from Brew Type)'),
                        ),
                      // Only show static options that aren't already the selected brew type
                      if (_selectedBrewType?.toLowerCase() != 'espresso')
                        const DropdownMenuItem(value: 'Espresso', child: Text('Espresso')),
                      if (_selectedBrewType?.toLowerCase() != 'drip')
                        const DropdownMenuItem(value: 'Drip', child: Text('Drip')),
                      if (_selectedBrewType?.toLowerCase() != 'pour over')
                        const DropdownMenuItem(value: 'Pour Over', child: Text('Pour Over')),
                      if (_selectedBrewType?.toLowerCase() != 'french press')
                        const DropdownMenuItem(value: 'French Press', child: Text('French Press')),
                      if (_selectedBrewType?.toLowerCase() != 'cold brew')
                        const DropdownMenuItem(value: 'Cold Brew', child: Text('Cold Brew')),
                    ],
                    onChanged: (value) => setState(() {
                      _drinkBaseType = value;
                      // Clear espresso shot if not espresso
                      if (value?.toLowerCase() != 'espresso') {
                        _drinkEspressoShot = null;
                      }
                    }),
                  ),
                  // Espresso shot selection (only show if base type is Espresso)
                  if ((_drinkBaseType ?? _selectedBrewType)?.toLowerCase() == 'espresso') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _drinkEspressoShot,
                      decoration: const InputDecoration(
                        labelText: 'Espresso Shot',
                        hintText: 'Optional',
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Not specified')),
                        DropdownMenuItem(value: 'Single', child: Text('Single')),
                        DropdownMenuItem(value: 'Double', child: Text('Double')),
                      ],
                      onChanged: (value) => setState(() => _drinkEspressoShot = value),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Milk type and amount
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _drinkMilkType,
                          decoration: const InputDecoration(
                            labelText: 'Milk Type',
                            hintText: 'Optional',
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ...milkTypes.map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                )),
                          ],
                          onChanged: (value) => setState(() => _drinkMilkType = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _drinkMilkAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (ml)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ice checkbox
                  CheckboxListTile(
                    title: const Text('Iced'),
                    value: _drinkIce,
                    onChanged: (value) => setState(() => _drinkIce = value ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  // Show/Hide Details Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showDrinkRecipeDetails = !_showDrinkRecipeDetails;
                        });
                      },
                      icon: Icon(_showDrinkRecipeDetails ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showDrinkRecipeDetails ? 'Hide Details' : 'Show Syrups, Sweeteners & More'),
                    ),
                  ),
                  // Additional details (syrups, sweeteners, additions, instructions)
                  if (_showDrinkRecipeDetails) ...[
                    const SizedBox(height: 12),
                    // Syrups
                    Text('Syrups', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonSyrups.map((syrup) {
                        final isSelected = _drinkSyrups.contains(syrup);
                        return FilterChip(
                          label: Text(syrup),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _drinkSyrups.add(syrup);
                              } else {
                                _drinkSyrups.remove(syrup);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Sweeteners
                    Text('Sweeteners', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sweeteners.map((sweetener) {
                        final isSelected = _drinkSweeteners.contains(sweetener);
                        return FilterChip(
                          label: Text(sweetener),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _drinkSweeteners.add(sweetener);
                              } else {
                                _drinkSweeteners.remove(sweetener);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Other additions
                    Text('Other Additions', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: drinkAdditions.map((addition) {
                        final isSelected = _drinkOtherAdditions.contains(addition);
                        return FilterChip(
                          label: Text(addition),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _drinkOtherAdditions.add(addition);
                              } else {
                                _drinkOtherAdditions.remove(addition);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Instructions
                    TextFormField(
                      controller: _drinkInstructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Preparation Notes',
                        hintText: 'Optional instructions',
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Save as new recipe button
                  if (_drinkNameController.text.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final user = ref.read(userProfileProvider);
                        if (user == null) return;

                        final newRecipe = DrinkRecipe(
                          id: const Uuid().v4(),
                          userId: user.id,
                          name: _drinkNameController.text,
                          baseType: _drinkBaseType ?? _selectedBrewType,
                          espressoShot: _drinkEspressoShot,
                          milkType: _drinkMilkType,
                          milkAmountMl: _drinkMilkAmountController.text.isEmpty
                              ? null
                              : double.tryParse(_drinkMilkAmountController.text),
                          ice: _drinkIce,
                          syrups: List.from(_drinkSyrups),
                          sweeteners: List.from(_drinkSweeteners),
                          otherAdditions: List.from(_drinkOtherAdditions),
                          instructions: _drinkInstructionsController.text.isEmpty
                              ? null
                              : _drinkInstructionsController.text,
                        );

                        await ref
                            .read(drinkRecipesProvider.notifier)
                            .createRecipe(newRecipe);

                        setState(() {
                          _selectedDrinkRecipeId = newRecipe.id;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Recipe saved!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save as New Recipe'),
                    ),
                ],
              ),
            ],

            if (_currentFieldVisibility['rating'] == true) ...[
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
                  // SCA Cupping Scores (moved from separate section)
                  if (_shouldShowCuppingScores()) ...[
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: Text('SCA Cupping Scores', style: AppTextStyles.sectionHeader),
                      subtitle: const Text('Toggle to show/hide cupping score fields'),
                      value: _showScaCuppingFields,
                      onChanged: (value) {
                        setState(() {
                          _showScaCuppingFields = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_showScaCuppingFields) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Score each attribute from 0-10',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      if (_currentFieldVisibility['cuppingFragrance'] == true)
                        _buildScaSlider('Fragrance/Aroma (Dry)', _cuppingFragrance, (value) {
                          setState(() => _cuppingFragrance = value);
                        }),
                      if (_currentFieldVisibility['cuppingAroma'] == true)
                        _buildScaSlider('Aroma (Wet)', _cuppingAroma, (value) {
                          setState(() => _cuppingAroma = value);
                        }),
                      if (_currentFieldVisibility['cuppingFlavor'] == true)
                        _buildScaSlider('Flavor', _cuppingFlavor, (value) {
                          setState(() => _cuppingFlavor = value);
                        }),
                      if (_currentFieldVisibility['cuppingAftertaste'] == true)
                        _buildScaSlider('Aftertaste', _cuppingAftertaste, (value) {
                          setState(() => _cuppingAftertaste = value);
                        }),
                      if (_currentFieldVisibility['cuppingAcidity'] == true)
                        _buildScaSlider('Acidity', _cuppingAcidity, (value) {
                          setState(() => _cuppingAcidity = value);
                        }),
                      if (_currentFieldVisibility['cuppingBody'] == true)
                        _buildScaSlider('Body', _cuppingBody, (value) {
                          setState(() => _cuppingBody = value);
                        }),
                      if (_currentFieldVisibility['cuppingBalance'] == true)
                        _buildScaSlider('Balance', _cuppingBalance, (value) {
                          setState(() => _cuppingBalance = value);
                        }),
                      if (_currentFieldVisibility['cuppingSweetness'] == true)
                        _buildScaSlider('Sweetness', _cuppingSweetness, (value) {
                          setState(() => _cuppingSweetness = value);
                        }),
                      if (_currentFieldVisibility['cuppingCleanCup'] == true)
                        _buildScaSlider('Clean Cup', _cuppingCleanCup, (value) {
                          setState(() => _cuppingCleanCup = value);
                        }),
                      if (_currentFieldVisibility['cuppingUniformity'] == true)
                        _buildScaSlider('Uniformity', _cuppingUniformity, (value) {
                          setState(() => _cuppingUniformity = value);
                        }),
                      if (_currentFieldVisibility['cuppingOverall'] == true) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overall (Calculated Total)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _calculateScaOverall().toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_currentFieldVisibility['cuppingDefects'] == true) ...[
                        TextFormField(
                          controller: _cuppingDefectsController,
                          decoration: const InputDecoration(
                            labelText: 'Defects Notes',
                            hintText: 'Describe any defects found',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ],

            if (_currentFieldVisibility['tastingNotes'] == true ||
                _currentFieldVisibility['flavorTags'] == true) ...[
              const SizedBox(height: 24),
              // Tasting Notes Section
              _buildSection(
                'Tasting Notes',
                [
                  if (_currentFieldVisibility['tastingNotes'] == true)
                    TextFormField(
                      controller: _tastingNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Describe the taste, aroma, and experience...',
                      ),
                      maxLines: 4,
                    ),
                  if (_currentFieldVisibility['flavorTags'] == true) ...[
                    if (_currentFieldVisibility['tastingNotes'] == true)
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

            if (_currentFieldVisibility['photos'] == true) ...[
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
            if (_currentFieldVisibility['bestRecipe'] == true)
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

  // Helper methods for conditional field display
  bool _isEspressoBrew() {
    return _selectedBrewType?.toLowerCase() == 'espresso';
  }

  bool _isPourOverBrew() {
    final brewType = _selectedBrewType?.toLowerCase() ?? '';
    return brewType.contains('pour') ||
        brewType.contains('v60') ||
        brewType.contains('chemex') ||
        brewType.contains('kalita');
  }

  bool _shouldShowAdvancedBrewingParams() {
    return _currentFieldVisibility['preInfusionTime'] == true ||
        _currentFieldVisibility['pressureBars'] == true ||
        _currentFieldVisibility['yieldGrams'] == true ||
        _currentFieldVisibility['bloomAmount'] == true ||
        _currentFieldVisibility['bloomTime'] == true ||
        _currentFieldVisibility['pourSchedule'] == true ||
        _currentFieldVisibility['tds'] == true ||
        _currentFieldVisibility['extractionYield'] == true;
  }

  String _formatSecondsToMinSec(String? secondsText) {
    if (secondsText == null || secondsText.isEmpty) {
      return '';
    }
    final seconds = int.tryParse(secondsText);
    if (seconds == null) {
      return '';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _loadDrinkRecipe(DrinkRecipe recipe) {
    setState(() {
      _drinkNameController.text = recipe.name;
      _drinkBaseType = recipe.baseType;
      _drinkEspressoShot = recipe.espressoShot;
      _drinkMilkType = recipe.milkType;
      _drinkMilkAmountController.text = recipe.milkAmountMl?.toString() ?? '';
      _drinkIce = recipe.ice;
      _drinkSyrups = List.from(recipe.syrups);
      _drinkSweeteners = List.from(recipe.sweeteners);
      _drinkOtherAdditions = List.from(recipe.otherAdditions);
      _drinkInstructionsController.text = recipe.instructions ?? '';
    });
  }

  Widget _buildEquipmentDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBrown),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
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

  bool _shouldShowEnvironmentalConditions() {
    return _currentFieldVisibility['roomTemp'] == true ||
        _currentFieldVisibility['humidity'] == true ||
        _currentFieldVisibility['altitude'] == true ||
        _currentFieldVisibility['timeOfDay'] == true;
  }

  bool _shouldShowCuppingScores() {
    return _currentFieldVisibility['cuppingFragrance'] == true ||
        _currentFieldVisibility['cuppingAroma'] == true ||
        _currentFieldVisibility['cuppingFlavor'] == true ||
        _currentFieldVisibility['cuppingAftertaste'] == true ||
        _currentFieldVisibility['cuppingAcidity'] == true ||
        _currentFieldVisibility['cuppingBody'] == true ||
        _currentFieldVisibility['cuppingBalance'] == true ||
        _currentFieldVisibility['cuppingSweetness'] == true ||
        _currentFieldVisibility['cuppingCleanCup'] == true ||
        _currentFieldVisibility['cuppingUniformity'] == true ||
        _currentFieldVisibility['cuppingOverall'] == true ||
        _currentFieldVisibility['cuppingDefects'] == true;
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

  Widget _buildScaSlider(String label, double? value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              value?.toInt().toString() ?? '0',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBrown,
              ),
            ),
          ],
        ),
        Slider(
          value: value ?? 0.0,
          min: 0,
          max: 10,
          divisions: 10,
          onChanged: onChanged,
          activeColor: AppTheme.primaryBrown,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  int _calculateScaOverall() {
    double total = 0;
    int count = 0;

    final scores = [
      _cuppingFragrance,
      _cuppingAroma,
      _cuppingFlavor,
      _cuppingAftertaste,
      _cuppingAcidity,
      _cuppingBody,
      _cuppingBalance,
      _cuppingSweetness,
      _cuppingCleanCup,
      _cuppingUniformity,
    ];

    for (final score in scores) {
      if (score != null && score > 0) {
        total += score;
        count++;
      }
    }

    return count > 0 ? total.toInt() : 0;
  }

  Widget _buildPhotoThumbnail(String path) {
    final index = _photoPaths.indexOf(path);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewer(
              photoPaths: _photoPaths,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
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
      ),
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
    final tempVisibility = Map<String, bool>.from(_currentFieldVisibility);

    // SCA field keys for master toggle
    final scaFields = [
      'cuppingFragrance',
      'cuppingAroma',
      'cuppingFlavor',
      'cuppingAftertaste',
      'cuppingAcidity',
      'cuppingBody',
      'cuppingBalance',
      'cuppingSweetness',
      'cuppingCleanCup',
      'cuppingUniformity',
      'cuppingOverall',
      'cuppingTotal',
      'cuppingDefects',
    ];

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
                  // Check if this is the SCA Cupping section
                  final isScaSection = entry.key == 'SCA Cupping';

                  // Calculate SCA master toggle state
                  bool? scaMasterValue;
                  if (isScaSection) {
                    final scaValues = scaFields.map((key) => tempVisibility[key] ?? false).toList();
                    if (scaValues.every((v) => v == true)) {
                      scaMasterValue = true;
                    } else if (scaValues.every((v) => v == false)) {
                      scaMasterValue = false;
                    } else {
                      scaMasterValue = null; // Mixed state
                    }
                  }

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
                      // Show master toggle for SCA Cupping section
                      if (isScaSection)
                        CheckboxListTile(
                          title: const Text(
                            'SCA Cupping (All Fields)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: scaMasterValue ?? false,
                          tristate: true,
                          onChanged: (value) {
                            setDialogState(() {
                              final newValue = value ?? true;
                              for (final scaKey in scaFields) {
                                tempVisibility[scaKey] = newValue;
                              }
                            });
                          },
                        ),
                      // Show individual checkboxes for non-SCA sections only
                      if (!isScaSection)
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
                onPressed: () {
                  // Update per-cup field visibility
                  setState(() {
                    _currentFieldVisibility = tempVisibility;
                  });
                  Navigator.pop(context);
                  showSuccess(context, 'Field visibility updated for this cup');
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
        price: _priceController.text.isEmpty ? null : double.tryParse(_priceController.text),
        bagSizeGrams: _bagSizeController.text.isEmpty ? null : double.tryParse(_bagSizeController.text),
        recommendedRestDays: _restDaysController.text.isEmpty ? null : int.tryParse(_restDaysController.text),
        datePurchased: _datePurchased,
        roastDate: _roastDate,
        openDate: _openDate ?? DateTime.now(),
      );

      await ref.read(bagsProvider.notifier).createBag(bag);
    } else {
      // Should not happen
      if (mounted) showError(context, 'Invalid state');
      return;
    }

    // Get grinder settings from selected equipment (for sharing)
    final equipment = _selectedEquipmentId != null
        ? ref.read(equipmentByIdProvider(_selectedEquipmentId!))
        : null;

    // Create or update cup
    final cupId = widget.cupId ?? uuid.v4();
    final cup = Cup(
      id: cupId,
      bagId: finalBagId,
      userId: user.id,
      brewType: _selectedBrewType!,
      grindLevel: _grindLevelController.text.isEmpty ? null : _grindLevelController.text,
      grinderMinSetting: equipment?.grinderMinSetting,
      grinderMaxSetting: equipment?.grinderMaxSetting,
      grinderStepSize: equipment?.grinderStepSize,
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
      // Advanced brewing parameters
      preInfusionTimeSeconds: _preInfusionTimeController.text.isEmpty
          ? null
          : int.tryParse(_preInfusionTimeController.text),
      pressureBars: _pressureBarsController.text.isEmpty
          ? null
          : double.tryParse(_pressureBarsController.text),
      yieldGrams: _yieldGramsController.text.isEmpty
          ? null
          : double.tryParse(_yieldGramsController.text),
      bloomAmountGrams: _bloomAmountController.text.isEmpty
          ? null
          : double.tryParse(_bloomAmountController.text),
      pourSchedule: _pourScheduleController.text.isEmpty
          ? null
          : _pourScheduleController.text,
      tds: _tdsController.text.isEmpty
          ? null
          : double.tryParse(_tdsController.text),
      extractionYield: _extractionYieldController.text.isEmpty
          ? null
          : double.tryParse(_extractionYieldController.text),
      // Environmental conditions
      roomTempCelsius: _roomTempController.text.isEmpty
          ? null
          : double.tryParse(_roomTempController.text),
      humidity: _humidityController.text.isEmpty
          ? null
          : double.tryParse(_humidityController.text),
      altitudeMeters: _altitudeController.text.isEmpty
          ? null
          : int.tryParse(_altitudeController.text),
      timeOfDay: _timeOfDay,
      // SCA cupping scores
      cuppingFragrance: _cuppingFragrance,
      cuppingAroma: _cuppingAroma,
      cuppingFlavor: _cuppingFlavor,
      cuppingAftertaste: _cuppingAftertaste,
      cuppingAcidity: _cuppingAcidity,
      cuppingBody: _cuppingBody,
      cuppingBalance: _cuppingBalance,
      cuppingSweetness: _cuppingSweetness,
      cuppingCleanCup: _cuppingCleanCup,
      cuppingUniformity: _cuppingUniformity,
      cuppingOverall: _calculateScaOverall() > 0 ? _calculateScaOverall().toDouble() : null,
      cuppingDefects: _cuppingDefectsController.text.isEmpty
          ? null
          : _cuppingDefectsController.text,
      tastingNotes: _tastingNotesController.text.isEmpty
          ? null
          : _tastingNotesController.text,
      flavorTags: _selectedFlavorTags,
      photoPaths: _photoPaths,
      isBest: _isBest,
      equipmentSetupId: _selectedEquipmentId,
      drinkRecipeId: _selectedDrinkRecipeId,
      fieldVisibility: _currentFieldVisibility,
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

  void _parsePourSchedule(String? schedule) {
    if (schedule == null || schedule.isEmpty) {
      _usePourTimer = false;
      _pourEntries = [];
      return;
    }

    // Check if it's timer format (has entries with timestamps)
    if (schedule.contains(':')) {
      _usePourTimer = true;
      // Simple parsing - entries are formatted like "00:45 - 50g"
      // This allows backward compatibility with text entries
    }
  }

  String _formatPourEntries(List<PourEntry> entries) {
    if (entries.isEmpty) return '';
    return entries.map((e) => e.toString()).join(', ');
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
    _priceController.dispose();
    _bagSizeController.dispose();
    _restDaysController.dispose();
    _grindLevelController.dispose();
    _waterTempController.dispose();
    _gramsUsedController.dispose();
    _finalVolumeController.dispose();
    _brewTimeController.dispose();
    _bloomTimeController.dispose();
    _tastingNotesController.dispose();

    // Dispose advanced brewing parameter controllers
    _preInfusionTimeController.dispose();
    _pressureBarsController.dispose();
    _yieldGramsController.dispose();
    _bloomAmountController.dispose();
    _pourScheduleController.dispose();
    _tdsController.dispose();
    _extractionYieldController.dispose();

    // Dispose environmental condition controllers
    _roomTempController.dispose();
    _humidityController.dispose();
    _altitudeController.dispose();

    // Dispose SCA cupping defects controller (other SCA fields use sliders, not controllers)
    _cuppingDefectsController.dispose();

    // Dispose drink recipe controllers
    _drinkNameController.dispose();
    _drinkMilkAmountController.dispose();
    _drinkInstructionsController.dispose();
    _brewTimeFormattedController.dispose();

    super.dispose();
  }
}
