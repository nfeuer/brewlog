import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/coffee_bag.dart';
import '../providers/bags_provider.dart';
import '../providers/user_provider.dart';
import '../services/photo_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class BagFormScreen extends ConsumerStatefulWidget {
  final CoffeeBag? bag; // null for new bag, existing bag for edit

  const BagFormScreen({super.key, this.bag});

  @override
  ConsumerState<BagFormScreen> createState() => _BagFormScreenState();
}

class _BagFormScreenState extends ConsumerState<BagFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = PhotoService();

  // Form controllers
  final _customTitleController = TextEditingController();
  final _coffeeNameController = TextEditingController();
  final _roasterController = TextEditingController();
  final _farmerController = TextEditingController();
  final _varietyController = TextEditingController();
  final _elevationController = TextEditingController();
  final _beanAromaController = TextEditingController();
  final _priceController = TextEditingController();
  final _bagSizeController = TextEditingController();

  String? _labelPhotoPath;
  DateTime? _datePurchased;
  DateTime? _roastDate;
  DateTime? _openDate;

  @override
  void initState() {
    super.initState();
    if (widget.bag != null) {
      _loadBagData();
    }
  }

  void _loadBagData() {
    final bag = widget.bag!;
    _customTitleController.text = bag.customTitle;
    _coffeeNameController.text = bag.coffeeName;
    _roasterController.text = bag.roaster;
    _farmerController.text = bag.farmer ?? '';
    _varietyController.text = bag.variety ?? '';
    _elevationController.text = bag.elevation ?? '';
    _beanAromaController.text = bag.beanAroma ?? '';
    _priceController.text = bag.price?.toString() ?? '';
    _bagSizeController.text = bag.bagSizeGrams?.toString() ?? '';
    _labelPhotoPath = bag.labelPhotoPath;
    _datePurchased = bag.datePurchased;
    _roastDate = bag.roastDate;
    _openDate = bag.openDate;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bag != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Coffee Bag' : 'New Coffee Bag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBag,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppStyles.screenPadding,
          children: [
            // Photo
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // Basic Info
            _buildSection(
              'Basic Information',
              [
                TextFormField(
                  controller: _customTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Title',
                    hintText: 'Optional nickname for this bag',
                  ),
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
              ],
            ),

            const SizedBox(height: 24),

            // Coffee Details
            _buildSection(
              'Coffee Details',
              [
                TextFormField(
                  controller: _farmerController,
                  decoration: const InputDecoration(labelText: 'Farmer'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _varietyController,
                  decoration: const InputDecoration(labelText: 'Variety'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _elevationController,
                  decoration: const InputDecoration(labelText: 'Elevation'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _beanAromaController,
                  decoration: const InputDecoration(labelText: 'Bean Aroma'),
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Purchase & Tracking
            _buildSection(
              'Purchase & Tracking',
              [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bagSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Bag Size',
                          suffixText: 'g',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  'Date Purchased',
                  _datePurchased,
                  (date) => setState(() => _datePurchased = date),
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  'Roast Date',
                  _roastDate,
                  (date) => setState(() => _roastDate = date),
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  'Open Date',
                  _openDate,
                  (date) => setState(() => _openDate = date),
                ),
              ],
            ),

            const SizedBox(height: 80),
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

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _changePhoto,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.accentCream,
          borderRadius: BorderRadius.circular(12),
          image: _labelPhotoPath != null
              ? DecorationImage(
                  image: FileImage(File(_labelPhotoPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _labelPhotoPath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: AppTheme.primaryBrown),
                  SizedBox(height: 8),
                  Text('Tap to add bag label photo'),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? formatDate(value) : 'Not set',
          style: value == null
              ? const TextStyle(color: Colors.grey)
              : null,
        ),
      ),
    );
  }

  void _changePhoto() async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Photo'),
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
          if (_labelPhotoPath != null)
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'remove'),
              icon: const Icon(Icons.delete),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    if (source == 'remove') {
      setState(() => _labelPhotoPath = null);
      return;
    }

    String? path;
    if (source == 'camera') {
      path = await _photoService.takePhoto();
    } else {
      path = await _photoService.pickPhoto();
    }

    if (path != null) {
      setState(() => _labelPhotoPath = path);
    }
  }

  void _saveBag() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProfileProvider);
    if (user == null) return;

    final bag = CoffeeBag(
      id: widget.bag?.id ?? const Uuid().v4(),
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
      labelPhotoPath: _labelPhotoPath,
      price: _priceController.text.isEmpty ? null : double.tryParse(_priceController.text),
      bagSizeGrams: _bagSizeController.text.isEmpty ? null : double.tryParse(_bagSizeController.text),
      datePurchased: _datePurchased,
      roastDate: _roastDate,
      openDate: _openDate,
      bagStatusIndex: widget.bag?.bagStatusIndex ?? BagStatus.active.index,
      totalCups: widget.bag?.totalCups ?? 0,
      avgScore: widget.bag?.avgScore,
      bestCupId: widget.bag?.bestCupId,
      createdAt: widget.bag?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final bagsNotifier = ref.read(bagsProvider.notifier);
    if (widget.bag != null) {
      await bagsNotifier.updateBag(bag);
      if (mounted) {
        showSuccess(context, 'Bag updated!');
      }
    } else {
      await bagsNotifier.createBag(bag);
      if (mounted) {
        showSuccess(context, 'Bag created!');
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _coffeeNameController.dispose();
    _roasterController.dispose();
    _farmerController.dispose();
    _varietyController.dispose();
    _elevationController.dispose();
    _beanAromaController.dispose();
    _priceController.dispose();
    _bagSizeController.dispose();
    super.dispose();
  }
}
