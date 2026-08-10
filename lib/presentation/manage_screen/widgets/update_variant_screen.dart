import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/realtime_database_repository.dart';
import '../../../theme/app_theme.dart';

class UpdateVariantScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String varietyId;
  final String varietyName;
  final Map<String, dynamic> variant;

  const UpdateVariantScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.varietyId,
    required this.varietyName,
    required this.variant,
  });

  @override
  State<UpdateVariantScreen> createState() =>
      _UpdateVariantScreenState();
}

class _UpdateVariantScreenState
    extends State<UpdateVariantScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _variantNameController;
  late final TextEditingController _weightController;
  late final TextEditingController _yearsController;
  late final TextEditingController _priceController;

  // ============================================================
  // IMAGE
  // ============================================================

  XFile? _selectedImage;

  String? _existingImageUrl;

  bool _isSaving = false;
  bool _isPickingImage = false;

  // ============================================================
  // VARIANT ID
  // ============================================================

  String get _variantId {
    return widget.variant['id']?.toString() ?? '';
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _variantNameController =
        TextEditingController(
          text: widget.variant['name']?.toString() ?? '',
        );

    _weightController =
        TextEditingController(
          text: widget.variant['weight']?.toString() ?? '',
        );

    _yearsController =
        TextEditingController(
          text: widget.variant['years']?.toString() ?? '',
        );

    _priceController =
        TextEditingController(
          text: widget.variant['price']?.toString() ?? '',
        );

    _existingImageUrl =
        widget.variant['imageUrl']?.toString();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _variantNameController.dispose();
    _weightController.dispose();
    _yearsController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickImage(
      ImageSource source,
      ) async {
    if (_isSaving || _isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              source == ImageSource.camera
                  ? 'Unable to open camera.'
                  : 'Unable to select image.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  // ============================================================
  // IMAGE SOURCE BOTTOM SHEET
  // ============================================================

  Future<void> _showImageSourceOptions() async {
    if (_isSaving || _isPickingImage) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext)
                  .colorScheme
                  .surface,
              borderRadius:
              const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // HANDLE
                // ------------------------------------------------

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Update Variant Image',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Take a new photo or choose an image from gallery.',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // OPTIONS
                // ------------------------------------------------

                Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceOption(
                        context: sheetContext,
                        icon:
                        Icons.camera_alt_rounded,
                        title: 'Take Photo',
                        subtitle: 'Use camera',
                        onTap: () async {
                          Navigator.pop(
                            sheetContext,
                          );

                          await _pickImage(
                            ImageSource.camera,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildImageSourceOption(
                        context: sheetContext,
                        icon:
                        Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle: 'Choose image',
                        onTap: () async {
                          Navigator.pop(
                            sheetContext,
                          );

                          await _pickImage(
                            ImageSource.gallery,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // IMAGE SOURCE OPTION
  // ============================================================

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Ink(
          padding:
          const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color:
            AppTheme.surfaceVariantLight,
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                  AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveChanges() async {
    final name =
    _variantNameController.text.trim();

    final weightText =
    _weightController.text.trim();

    final yearsText =
    _yearsController.text.trim();

    final priceText =
    _priceController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showMessage(
        'Please enter variant name',
      );
      return;
    }

    if (weightText.isEmpty) {
      _showMessage(
        'Please enter weight',
      );
      return;
    }

    if (yearsText.isEmpty) {
      _showMessage(
        'Please enter plant age',
      );
      return;
    }

    if (priceText.isEmpty) {
      _showMessage(
        'Please enter price',
      );
      return;
    }

    final weight =
    double.tryParse(weightText);

    final years =
    int.tryParse(yearsText);

    final price =
    double.tryParse(priceText);

    if (weight == null) {
      _showMessage(
        'Please enter a valid weight',
      );
      return;
    }

    if (years == null) {
      _showMessage(
        'Please enter a valid plant age',
      );
      return;
    }

    if (price == null) {
      _showMessage(
        'Please enter a valid price',
      );
      return;
    }

    if (_variantId.isEmpty) {
      _showMessage(
        'Unable to identify this variant',
      );
      return;
    }

    // ----------------------------------------------------------
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      await RealtimeDatabaseRepository
          .instance
          .updateVariant(
        plantId: widget.plantId,
        varietyId: widget.varietyId,
        variantId: _variantId,
        name: name,
        weight: weight,
        years: years,
        price: price,
        image: _selectedImage,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Variant updated successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to update variant: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // READ ONLY FIELD
  // ============================================================

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius:
            BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Colors.grey.shade700,
                  ),
                ),
              ),

              Icon(
                Icons.lock_outline_rounded,
                size: 17,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDITABLE TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: keyboardType,
          textCapitalization:
          TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            prefixText: prefixText,
            suffixText: suffixText,
            filled: true,
            fillColor:
            AppTheme.surfaceVariantLight,
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide:
              const BorderSide(
                color: AppTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget _buildImageSection() {
    final hasNewImage =
        _selectedImage != null;

    final hasExistingImage =
        _existingImageUrl != null &&
            _existingImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Variant Image',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            Text(
              'Optional',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color:
                Colors.grey.shade500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        GestureDetector(
          onTap: _isSaving ||
              _isPickingImage
              ? null
              : _showImageSourceOptions,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color:
              AppTheme.surfaceVariantLight,
              borderRadius:
              BorderRadius.circular(18),
              border: Border.all(
                color: hasNewImage
                    ? AppTheme.primary
                    .withAlpha(100)
                    : Colors.grey.shade300,
                width:
                hasNewImage ? 1.5 : 1,
              ),
            ),
            child: hasNewImage
                ? _buildSelectedImage()
                : hasExistingImage
                ? _buildExistingImage()
                : _buildNoImage(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NEW IMAGE
  // ============================================================

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
          BorderRadius.circular(17),
          child: Image.file(
            File(_selectedImage!.path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        _buildImageOverlay(),
      ],
    );
  }

  // ============================================================
  // EXISTING IMAGE
  // ============================================================

  Widget _buildExistingImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
          BorderRadius.circular(17),
          child: Image.network(
            _existingImageUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) {
              return _buildNoImage();
            },
          ),
        ),

        _buildImageOverlay(),
      ],
    );
  }

  // ============================================================
  // IMAGE OVERLAY
  // ============================================================

  Widget _buildImageOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Bottom gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(17),
                gradient:
                LinearGradient(
                  begin:
                  Alignment.topCenter,
                  end:
                  Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(140),
                  ],
                ),
              ),
            ),
          ),

          // Edit button
          Positioned(
            right: 12,
            top: 12,
            child: Material(
              color:
              Colors.black.withAlpha(130),
              borderRadius:
              BorderRadius.circular(12),
              child: InkWell(
                borderRadius:
                BorderRadius.circular(12),
                onTap: _isSaving ||
                    _isPickingImage
                    ? null
                    : _showImageSourceOptions,
                child: const Padding(
                  padding:
                  EdgeInsets.all(10),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Bottom text
          const Positioned(
            left: 14,
            bottom: 14,
            child: Row(
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'Tap to change image',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO IMAGE
  // ============================================================

  Widget _buildNoImage() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppTheme.primary
                  .withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Add Variant Image',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Take a photo or choose from gallery',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      AppTheme.backgroundLight,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
        theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: _isSaving
              ? null
              : () => Navigator.pop(
            context,
          ),
        ),

        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Update Variant',
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            Text(
              widget.varietyName,
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color:
                Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            110,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // PARENT CONTEXT
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(16),
                decoration:
                BoxDecoration(
                  color: theme
                      .colorScheme
                      .surface,
                  borderRadius:
                  BorderRadius.circular(
                    22,
                  ),
                  border:
                  Border.all(
                    color: AppTheme
                        .primary
                        .withAlpha(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme
                          .primary
                          .withAlpha(8),
                      blurRadius: 14,
                      offset:
                      const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                      _buildParentInfo(
                        icon:
                        Icons.eco_rounded,
                        label:
                        'PARENT PLANT',
                        value:
                        widget.plantName,
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 54,
                      color:
                      Colors.grey.shade200,
                    ),

                    Expanded(
                      child:
                      _buildParentInfo(
                        icon: Icons
                            .account_tree_rounded,
                        label:
                        'PARENT VARIETY',
                        value:
                        widget.varietyName,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // DETAILS HEADING
              // ==================================================

              Row(
                children: [
                  Text(
                    'VARIANT DETAILS',
                    style: theme
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: 1.2,
                      color:
                      Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 1,
                      color:
                      Colors.grey.shade200,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // VARIANT NAME
              // ==================================================

              _buildTextField(
                controller:
                _variantNameController,
                label:
                'Variant Name',
                hint:
                'Example: Alphonso 5Kg',
                icon:
                Icons.inventory_2_outlined,
              ),

              const SizedBox(height: 16),

              // ==================================================
              // WEIGHT
              // ==================================================

              _buildTextField(
                controller:
                _weightController,
                label:
                'Weight',
                hint:
                'Example: 5',
                icon:
                Icons.scale_rounded,
                keyboardType:
                const TextInputType
                    .numberWithOptions(
                  decimal: true,
                ),
                suffixText:
                'kg',
              ),

              const SizedBox(height: 16),

              // ==================================================
              // PLANT AGE
              // ==================================================

              _buildTextField(
                controller:
                _yearsController,
                label:
                'Plant Age',
                hint:
                'Example: 2',
                icon:
                Icons.calendar_month_rounded,
                keyboardType:
                TextInputType.number,
                suffixText:
                'years',
              ),

              const SizedBox(height: 16),

              // ==================================================
              // PRICE
              // ==================================================

              _buildTextField(
                controller:
                _priceController,
                label:
                'Price',
                hint:
                'Example: 500',
                icon:
                Icons.currency_rupee_rounded,
                keyboardType:
                const TextInputType
                    .numberWithOptions(
                  decimal: true,
                ),
                prefixText:
                '₹ ',
              ),

              const SizedBox(height: 24),

              // ==================================================
              // IMAGE
              // ==================================================

              _buildImageSection(),
            ],
          ),
        ),
      ),

      // ==========================================================
      // SAVE BUTTON
      // ==========================================================

      bottomNavigationBar:
      SafeArea(
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12,
          ),
          color:
          theme.colorScheme.surface,
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
              _isSaving
                  ? null
                  : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.save_rounded,
              ),
              label: Text(
                _isSaving
                    ? 'Saving Changes...'
                    : 'Save Changes',
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                AppTheme.primary,
                foregroundColor:
                Colors.white,
                elevation: 2,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PARENT INFORMATION
  // ============================================================

  Widget _buildParentInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primary,
            size: 22,
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight:
              FontWeight.w800,
              letterSpacing: 0.7,
              color:
              Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}