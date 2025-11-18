import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment_setup.dart';
import '../providers/equipment_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class EquipmentFormScreen extends ConsumerStatefulWidget {
  final String userId;
  final EquipmentSetup? equipment;

  const EquipmentFormScreen({
    super.key,
    required this.userId,
    this.equipment,
  });

  @override
  ConsumerState<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends ConsumerState<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _grinderBrandController = TextEditingController();
  final _grinderModelController = TextEditingController();
  final _grinderNotesController = TextEditingController();
  final _brewerBrandController = TextEditingController();
  final _brewerModelController = TextEditingController();
  final _waterBrandController = TextEditingController();
  final _scaleBrandController = TextEditingController();
  final _scaleModelController = TextEditingController();
  final _kettleBrandController = TextEditingController();
  final _espressoMachineController = TextEditingController();

  String? _selectedGrinderType;
  String? _selectedWaterType;
  String? _selectedFilterType;
  String? _selectedKettleType;
  double? _waterTDS;
  double? _scaleAccuracy;
  bool? _hasTemperatureControl;
  double? _boilerTemp;
  double? _brewPressure;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.equipment != null) {
      final equipment = widget.equipment!;
      _nameController.text = equipment.name;
      _grinderBrandController.text = equipment.grinderBrand ?? '';
      _grinderModelController.text = equipment.grinderModel ?? '';
      _selectedGrinderType = equipment.grinderType;
      _grinderNotesController.text = equipment.grinderNotes ?? '';
      _brewerBrandController.text = equipment.brewerBrand ?? '';
      _brewerModelController.text = equipment.brewerModel ?? '';
      _selectedFilterType = equipment.filterType;
      _selectedWaterType = equipment.waterType;
      _waterTDS = equipment.waterTDS;
      _waterBrandController.text = equipment.waterBrand ?? '';
      _scaleBrandController.text = equipment.scaleBrand ?? '';
      _scaleModelController.text = equipment.scaleModel ?? '';
      _scaleAccuracy = equipment.scaleAccuracy;
      _kettleBrandController.text = equipment.kettleBrand ?? '';
      _selectedKettleType = equipment.kettleType;
      _hasTemperatureControl = equipment.hasTemperatureControl;
      _espressoMachineController.text = equipment.espressoMachine ?? '';
      _boilerTemp = equipment.boilerTemp;
      _brewPressure = equipment.brewPressure;
      _isDefault = equipment.isDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment == null ? 'New Equipment Setup' : 'Edit Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEquipment,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppStyles.screenPadding,
          children: [
            // Setup Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Setup Name *',
                hintText: 'e.g., Home Setup, Travel Kit',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Set as Default'),
              subtitle: const Text('Use this equipment by default for new cups'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Grinder Section
            _buildSectionHeader('Grinder'),
            TextFormField(
              controller: _grinderBrandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grinderModelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGrinderType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: grinderTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGrinderType = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grinderNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g., Click settings, grind size reference',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Brewer Section
            _buildSectionHeader('Brewer'),
            TextFormField(
              controller: _brewerBrandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brewerModelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFilterType,
              decoration: const InputDecoration(labelText: 'Filter Type'),
              items: filterTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedFilterType = value),
            ),
            const SizedBox(height: 24),

            // Water Section
            _buildSectionHeader('Water'),
            DropdownButtonFormField<String>(
              value: _selectedWaterType,
              decoration: const InputDecoration(labelText: 'Water Type'),
              items: waterTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedWaterType = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _waterBrandController,
              decoration: const InputDecoration(
                labelText: 'Brand/Details',
                hintText: 'e.g., Third Wave Water - Classic',
              ),
            ),
            const SizedBox(height: 24),

            // Scale Section
            _buildSectionHeader('Scale'),
            TextFormField(
              controller: _scaleBrandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _scaleModelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Accuracy (grams)',
                hintText: 'e.g., 0.1 or 0.01',
              ),
              keyboardType: TextInputType.number,
              initialValue: _scaleAccuracy?.toString(),
              onChanged: (value) => _scaleAccuracy = double.tryParse(value),
            ),
            const SizedBox(height: 24),

            // Kettle Section
            _buildSectionHeader('Kettle'),
            TextFormField(
              controller: _kettleBrandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedKettleType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: kettleTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedKettleType = value),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Temperature Control'),
              value: _hasTemperatureControl ?? false,
              onChanged: (value) => setState(() => _hasTemperatureControl = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Espresso Section (Optional)
            _buildSectionHeader('Espresso Machine (Optional)'),
            TextFormField(
              controller: _espressoMachineController,
              decoration: const InputDecoration(labelText: 'Machine'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Boiler Temp (°C)'),
              keyboardType: TextInputType.number,
              initialValue: _boilerTemp?.toString(),
              onChanged: (value) => _boilerTemp = double.tryParse(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Brew Pressure (bar)'),
              keyboardType: TextInputType.number,
              initialValue: _brewPressure?.toString(),
              onChanged: (value) => _brewPressure = double.tryParse(value),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.sectionHeader.copyWith(
          color: AppTheme.primaryBrown,
        ),
      ),
    );
  }

  void _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    final equipment = EquipmentSetup(
      id: widget.equipment?.id ?? const Uuid().v4(),
      userId: widget.userId,
      name: _nameController.text,
      grinderBrand: _grinderBrandController.text.isEmpty
          ? null
          : _grinderBrandController.text,
      grinderModel: _grinderModelController.text.isEmpty
          ? null
          : _grinderModelController.text,
      grinderType: _selectedGrinderType,
      grinderNotes: _grinderNotesController.text.isEmpty
          ? null
          : _grinderNotesController.text,
      brewerBrand: _brewerBrandController.text.isEmpty
          ? null
          : _brewerBrandController.text,
      brewerModel: _brewerModelController.text.isEmpty
          ? null
          : _brewerModelController.text,
      filterType: _selectedFilterType,
      waterType: _selectedWaterType,
      waterTDS: _waterTDS,
      waterBrand:
          _waterBrandController.text.isEmpty ? null : _waterBrandController.text,
      scaleBrand:
          _scaleBrandController.text.isEmpty ? null : _scaleBrandController.text,
      scaleModel:
          _scaleModelController.text.isEmpty ? null : _scaleModelController.text,
      scaleAccuracy: _scaleAccuracy,
      kettleBrand: _kettleBrandController.text.isEmpty
          ? null
          : _kettleBrandController.text,
      kettleType: _selectedKettleType,
      hasTemperatureControl: _hasTemperatureControl,
      espressoMachine: _espressoMachineController.text.isEmpty
          ? null
          : _espressoMachineController.text,
      boilerTemp: _boilerTemp,
      brewPressure: _brewPressure,
      isDefault: _isDefault,
      createdAt: widget.equipment?.createdAt,
    );

    final equipmentNotifier = ref.read(equipmentProvider.notifier);
    if (widget.equipment == null) {
      await equipmentNotifier.createEquipment(equipment);
    } else {
      await equipmentNotifier.updateEquipment(equipment);
    }

    if (mounted) {
      showSuccess(context, 'Equipment saved!');
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _grinderBrandController.dispose();
    _grinderModelController.dispose();
    _grinderNotesController.dispose();
    _brewerBrandController.dispose();
    _brewerModelController.dispose();
    _waterBrandController.dispose();
    _scaleBrandController.dispose();
    _scaleModelController.dispose();
    _kettleBrandController.dispose();
    _espressoMachineController.dispose();
    super.dispose();
  }
}
