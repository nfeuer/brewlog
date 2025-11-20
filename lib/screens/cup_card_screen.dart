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
import '../widgets/photo_viewer.dart';
import '../widgets/temperature_dial.dart';
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
  final _bloomTimeController = TextEditingController();
  final _tastingNotesController = TextEditingController();

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

  // SCA cupping score controllers
  final _cuppingFragranceController = TextEditingController();
  final _cuppingAromaController = TextEditingController();
  final _cuppingFlavorController = TextEditingController();
  final _cuppingAftertasteController = TextEditingController();
  final _cuppingAcidityController = TextEditingController();
  final _cuppingBodyController = TextEditingController();
  final _cuppingBalanceController = TextEditingController();
  final _cuppingSweetnessController = TextEditingController();
  final _cuppingCleanCupController = TextEditingController();
  final _cuppingUniformityController = TextEditingController();
  final _cuppingOverallController = TextEditingController();
  final _cuppingDefectsController = TextEditingController();

  String? _selectedBrewType;
  String? _selectedEquipmentId;
  String? _timeOfDay;
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

        // Load advanced brewing parameters
        _preInfusionTimeController.text = cup.preInfusionTimeSeconds?.toString() ?? '';
        _pressureBarsController.text = cup.pressureBars?.toString() ?? '';
        _yieldGramsController.text = cup.yieldGrams?.toString() ?? '';
        _bloomAmountController.text = cup.bloomAmountGrams?.toString() ?? '';
        _pourScheduleController.text = cup.pourSchedule ?? '';
        _tdsController.text = cup.tds?.toString() ?? '';
        _extractionYieldController.text = cup.extractionYield?.toString() ?? '';

        // Load environmental conditions
        _roomTempController.text = cup.roomTempCelsius?.toString() ?? '';
        _humidityController.text = cup.humidity?.toString() ?? '';
        _altitudeController.text = cup.altitudeMeters?.toString() ?? '';
        _timeOfDay = cup.timeOfDay;

        // Load SCA cupping scores
        _cuppingFragranceController.text = cup.cuppingFragrance?.toString() ?? '';
        _cuppingAromaController.text = cup.cuppingAroma?.toString() ?? '';
        _cuppingFlavorController.text = cup.cuppingFlavor?.toString() ?? '';
        _cuppingAftertasteController.text = cup.cuppingAftertaste?.toString() ?? '';
        _cuppingAcidityController.text = cup.cuppingAcidity?.toString() ?? '';
        _cuppingBodyController.text = cup.cuppingBody?.toString() ?? '';
        _cuppingBalanceController.text = cup.cuppingBalance?.toString() ?? '';
        _cuppingSweetnessController.text = cup.cuppingSweetness?.toString() ?? '';
        _cuppingCleanCupController.text = cup.cuppingCleanCup?.toString() ?? '';
        _cuppingUniformityController.text = cup.cuppingUniformity?.toString() ?? '';
        _cuppingOverallController.text = cup.cuppingOverall?.toString() ?? '';
        _cuppingDefectsController.text = cup.cuppingDefects ?? '';

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
          _priceController.text = bag.price?.toString() ?? '';
          _bagSizeController.text = bag.bagSizeGrams?.toString() ?? '';
          _restDaysController.text = bag.recommendedRestDays?.toString() ?? '';
          _datePurchased = bag.datePurchased;
          _roastDate = bag.roastDate;
          _openDate = bag.openDate;
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
        _priceController.text = bag.price?.toString() ?? '';
        _bagSizeController.text = bag.bagSizeGrams?.toString() ?? '';
        _restDaysController.text = bag.recommendedRestDays?.toString() ?? '';
        _datePurchased = bag.datePurchased;
        _roastDate = bag.roastDate;
        _openDate = bag.openDate;
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

            // Advanced Brewing Parameters Section (brew-type specific)
            if (_shouldShowAdvancedBrewingParams()) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Advanced Brewing Parameters',
                [
                  // Espresso-specific fields
                  if (_isEspressoBrew()) ...[
                    if (fieldVisibility['preInfusionTime'] == true) ...[
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
                    if (fieldVisibility['pressureBars'] == true) ...[
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
                    if (fieldVisibility['yieldGrams'] == true) ...[
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
                    if (fieldVisibility['bloomAmount'] == true) ...[
                      TextFormField(
                        controller: _bloomAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Bloom Water Amount',
                          suffixText: 'g',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (fieldVisibility['pourSchedule'] == true) ...[
                      TextFormField(
                        controller: _pourScheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Pour Schedule',
                          hintText: 'e.g., 0:00-50g, 0:45-100g, 1:30-final',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  // TDS and Extraction (for all brew types, hidden by default)
                  if (fieldVisibility['tds'] == true) ...[
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
                  if (fieldVisibility['extractionYield'] == true) ...[
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
                  if (fieldVisibility['roomTemp'] == true) ...[
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
                  if (fieldVisibility['humidity'] == true) ...[
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
                  if (fieldVisibility['altitude'] == true) ...[
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
                  if (fieldVisibility['timeOfDay'] == true) ...[
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

            // SCA Cupping Scores Section
            if (_shouldShowCuppingScores()) ...[
              const SizedBox(height: 24),
              _buildSection(
                'SCA Cupping Scores',
                [
                  const Text(
                    'Score each attribute from 0-10',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (fieldVisibility['cuppingFragrance'] == true) ...[
                    TextFormField(
                      controller: _cuppingFragranceController,
                      decoration: const InputDecoration(
                        labelText: 'Fragrance/Aroma (Dry)',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingAroma'] == true) ...[
                    TextFormField(
                      controller: _cuppingAromaController,
                      decoration: const InputDecoration(
                        labelText: 'Aroma (Wet)',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingFlavor'] == true) ...[
                    TextFormField(
                      controller: _cuppingFlavorController,
                      decoration: const InputDecoration(
                        labelText: 'Flavor',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingAftertaste'] == true) ...[
                    TextFormField(
                      controller: _cuppingAftertasteController,
                      decoration: const InputDecoration(
                        labelText: 'Aftertaste',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingAcidity'] == true) ...[
                    TextFormField(
                      controller: _cuppingAcidityController,
                      decoration: const InputDecoration(
                        labelText: 'Acidity',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingBody'] == true) ...[
                    TextFormField(
                      controller: _cuppingBodyController,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingBalance'] == true) ...[
                    TextFormField(
                      controller: _cuppingBalanceController,
                      decoration: const InputDecoration(
                        labelText: 'Balance',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingSweetness'] == true) ...[
                    TextFormField(
                      controller: _cuppingSweetnessController,
                      decoration: const InputDecoration(
                        labelText: 'Sweetness',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingCleanCup'] == true) ...[
                    TextFormField(
                      controller: _cuppingCleanCupController,
                      decoration: const InputDecoration(
                        labelText: 'Clean Cup',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingUniformity'] == true) ...[
                    TextFormField(
                      controller: _cuppingUniformityController,
                      decoration: const InputDecoration(
                        labelText: 'Uniformity',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingOverall'] == true) ...[
                    TextFormField(
                      controller: _cuppingOverallController,
                      decoration: const InputDecoration(
                        labelText: 'Overall',
                        hintText: '0-10',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fieldVisibility['cuppingDefects'] == true) ...[
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
              ),
            ],

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
    final fieldVisibility = ref.watch(cupFieldVisibilityProvider);
    return fieldVisibility['preInfusionTime'] == true ||
        fieldVisibility['pressureBars'] == true ||
        fieldVisibility['yieldGrams'] == true ||
        fieldVisibility['bloomAmount'] == true ||
        fieldVisibility['pourSchedule'] == true ||
        fieldVisibility['tds'] == true ||
        fieldVisibility['extractionYield'] == true;
  }

  bool _shouldShowEnvironmentalConditions() {
    final fieldVisibility = ref.watch(cupFieldVisibilityProvider);
    return fieldVisibility['roomTemp'] == true ||
        fieldVisibility['humidity'] == true ||
        fieldVisibility['altitude'] == true ||
        fieldVisibility['timeOfDay'] == true;
  }

  bool _shouldShowCuppingScores() {
    final fieldVisibility = ref.watch(cupFieldVisibilityProvider);
    return fieldVisibility['cuppingFragrance'] == true ||
        fieldVisibility['cuppingAroma'] == true ||
        fieldVisibility['cuppingFlavor'] == true ||
        fieldVisibility['cuppingAftertaste'] == true ||
        fieldVisibility['cuppingAcidity'] == true ||
        fieldVisibility['cuppingBody'] == true ||
        fieldVisibility['cuppingBalance'] == true ||
        fieldVisibility['cuppingSweetness'] == true ||
        fieldVisibility['cuppingCleanCup'] == true ||
        fieldVisibility['cuppingUniformity'] == true ||
        fieldVisibility['cuppingOverall'] == true ||
        fieldVisibility['cuppingDefects'] == true;
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
      cuppingFragrance: _cuppingFragranceController.text.isEmpty
          ? null
          : double.tryParse(_cuppingFragranceController.text),
      cuppingAroma: _cuppingAromaController.text.isEmpty
          ? null
          : double.tryParse(_cuppingAromaController.text),
      cuppingFlavor: _cuppingFlavorController.text.isEmpty
          ? null
          : double.tryParse(_cuppingFlavorController.text),
      cuppingAftertaste: _cuppingAftertasteController.text.isEmpty
          ? null
          : double.tryParse(_cuppingAftertasteController.text),
      cuppingAcidity: _cuppingAcidityController.text.isEmpty
          ? null
          : double.tryParse(_cuppingAcidityController.text),
      cuppingBody: _cuppingBodyController.text.isEmpty
          ? null
          : double.tryParse(_cuppingBodyController.text),
      cuppingBalance: _cuppingBalanceController.text.isEmpty
          ? null
          : double.tryParse(_cuppingBalanceController.text),
      cuppingSweetness: _cuppingSweetnessController.text.isEmpty
          ? null
          : double.tryParse(_cuppingSweetnessController.text),
      cuppingCleanCup: _cuppingCleanCupController.text.isEmpty
          ? null
          : double.tryParse(_cuppingCleanCupController.text),
      cuppingUniformity: _cuppingUniformityController.text.isEmpty
          ? null
          : double.tryParse(_cuppingUniformityController.text),
      cuppingOverall: _cuppingOverallController.text.isEmpty
          ? null
          : double.tryParse(_cuppingOverallController.text),
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

    // Dispose SCA cupping score controllers
    _cuppingFragranceController.dispose();
    _cuppingAromaController.dispose();
    _cuppingFlavorController.dispose();
    _cuppingAftertasteController.dispose();
    _cuppingAcidityController.dispose();
    _cuppingBodyController.dispose();
    _cuppingBalanceController.dispose();
    _cuppingSweetnessController.dispose();
    _cuppingCleanCupController.dispose();
    _cuppingUniformityController.dispose();
    _cuppingOverallController.dispose();
    _cuppingDefectsController.dispose();

    super.dispose();
  }
}
