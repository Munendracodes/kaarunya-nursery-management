import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaarunyanursery/presentation/manage_screen/widgets/update_variant_screen.dart';

import '../../../services/realtime_database_repository.dart';
import '../../../theme/app_theme.dart';


class ManageVariantScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Map<String, dynamic> variety;

  const ManageVariantScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.variety,
  });

  @override
  State<ManageVariantScreen> createState() =>
      _ManageVariantScreenState();
}

class _ManageVariantScreenState
    extends State<ManageVariantScreen> {
  List<Map<String, dynamic>> _variants = [];

  bool _isLoading = true;

  String get _varietyId =>
      widget.variety['id']?.toString() ?? '';

  String get _varietyName =>
      widget.variety['name']?.toString() ??
          'Variety';

  String? get _varietyImageUrl =>
      widget.variety['imageUrl']?.toString();

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  // ============================================================
  // LOAD VARIANTS
  // ============================================================

  Future<void> _loadVariants() async {
    if (_varietyId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final variants =
      await RealtimeDatabaseRepository.instance
          .getVariants(
        widget.plantId,
        _varietyId,
      );

      if (mounted) {
        setState(() {
          _variants = variants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            content: Text(
              'Unable to load variants: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // ADD VARIANT
  // ============================================================

  void _showAddVariantDialog() {
    final variantNameController = TextEditingController();
    final weightController = TextEditingController();
    final yearsController = TextEditingController();
    final priceController = TextEditingController();

    XFile? selectedImage;

    bool isSaving = false;
    bool isPickingImage = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            // ============================================================
            // PICK IMAGE
            // ============================================================

            Future<void> pickImage(ImageSource source) async {
              if (isSaving || isPickingImage) return;

              setDialogState(() {
                isPickingImage = true;
              });

              try {
                final picker = ImagePicker();

                final image = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                  maxWidth: 1200,
                  maxHeight: 1200,
                );

                if (image != null && context.mounted) {
                  setDialogState(() {
                    selectedImage = image;
                  });
                }
              } catch (e, stackTrace) {
                debugPrint('Variant image picker error: $e');
                debugPrintStack(stackTrace: stackTrace);

                if (context.mounted) {
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
                if (context.mounted) {
                  setDialogState(() {
                    isPickingImage = false;
                  });
                }
              }
            }

            // ============================================================
            // IMAGE SOURCE OPTIONS
            // ============================================================

            Future<void> showImageSourceOptions() async {
              if (isSaving || isPickingImage) return;

              await showModalBottomSheet<void>(
                context: dialogContext,
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Add Variant Image',
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
                              'Take a photo or choose an image from gallery.',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _buildImageSourceOption(
                                  context: sheetContext,
                                  icon: Icons.camera_alt_rounded,
                                  title: 'Take Photo',
                                  subtitle: 'Use camera',
                                  onTap: () async {
                                    Navigator.pop(sheetContext);

                                    await pickImage(
                                      ImageSource.camera,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: _buildImageSourceOption(
                                  context: sheetContext,
                                  icon: Icons.photo_library_rounded,
                                  title: 'Gallery',
                                  subtitle: 'Choose image',
                                  onTap: () async {
                                    Navigator.pop(sheetContext);

                                    await pickImage(
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
            // SAVE VARIANT
            // ============================================================

            Future<void> saveVariant() async {
              final name = variantNameController.text.trim();
              final weight = weightController.text.trim();
              final years = yearsController.text.trim();
              final price = priceController.text.trim();

              if (name.isEmpty) {
                _showValidationMessage(
                  'Please enter variant name',
                );
                return;
              }

              if (weight.isEmpty) {
                _showValidationMessage(
                  'Please enter weight',
                );
                return;
              }

              if (years.isEmpty) {
                _showValidationMessage(
                  'Please enter plant age',
                );
                return;
              }

              if (price.isEmpty) {
                _showValidationMessage(
                  'Please enter price',
                );
                return;
              }

              final parsedWeight = double.tryParse(weight);
              final parsedYears = int.tryParse(years);
              final parsedPrice = double.tryParse(price);

              if (parsedWeight == null) {
                _showValidationMessage(
                  'Enter a valid weight',
                );
                return;
              }

              if (parsedYears == null) {
                _showValidationMessage(
                  'Enter a valid age',
                );
                return;
              }

              if (parsedPrice == null) {
                _showValidationMessage(
                  'Enter a valid price',
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await RealtimeDatabaseRepository.instance.addVariant(
                  plantId: widget.plantId,
                  varietyId: _varietyId,
                  name: name,
                  weight: parsedWeight,
                  years: parsedYears,
                  price: parsedPrice,
                  image: selectedImage,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                await _loadVariants();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Variant added successfully',
                      ),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                debugPrint(
                  'Failed to add variant: $e',
                );
                debugPrintStack(
                  stackTrace: stackTrace,
                );

                if (dialogContext.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Failed to add variant: $e',
                      ),
                    ),
                  );
                }
              }
            }

            // ============================================================
            // DIALOG
            // ============================================================

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(18),
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: AppTheme.primary,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Variant',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  'Add a new plant variant',
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

                          IconButton(
                            onPressed: isSaving
                                ? null
                                : () =>
                                Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // PLANT NAME
                      // ==================================================

                      _buildReadOnlyField(
                        label: 'Plant Name',
                        value: widget.plantName,
                        icon: Icons.eco_rounded,
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // VARIETY NAME
                      // ==================================================

                      _buildReadOnlyField(
                        label: 'Variety Name',
                        value: _varietyName,
                        icon: Icons.account_tree_rounded,
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // VARIANT NAME
                      // ==================================================

                      _buildTextField(
                        controller: variantNameController,
                        label: 'Variant Name',
                        hint: 'Example: Alphonso 5Kg',
                        icon: Icons.inventory_2_outlined,
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // IMAGE
                      // ==================================================

                      Text(
                        'Variant Image',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: isSaving || isPickingImage
                            ? null
                            : showImageSourceOptions,
                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(18),
                            color:
                            AppTheme.surfaceVariantLight,
                            border: Border.all(
                              color: selectedImage != null
                                  ? AppTheme.primary
                                  .withAlpha(100)
                                  : Colors.grey.shade300,
                              width: selectedImage != null
                                  ? 1.5
                                  : 1,
                            ),
                          ),
                          child: selectedImage == null
                              ? Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons
                                      .add_photo_alternate_rounded,
                                  color: AppTheme.primary,
                                  size: 30,
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
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color:
                                  Colors.grey.shade600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Tap to select',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                              : Stack(
                            children: [
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(17),
                                child: Image.file(
                                  File(selectedImage!.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(17),
                                    gradient: LinearGradient(
                                      begin:
                                      Alignment.topCenter,
                                      end:
                                      Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withAlpha(140),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

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
                                    onTap: isSaving ||
                                        isPickingImage
                                        ? null
                                        : showImageSourceOptions,
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

                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 12,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .check_circle_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        selectedImage!.name,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style:
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // WEIGHT
                      // ==================================================

                      _buildTextField(
                        controller: weightController,
                        label: 'Weight',
                        hint: 'Example: 5',
                        icon: Icons.scale_rounded,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        suffixText: 'kg',
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // YEARS
                      // ==================================================

                      _buildTextField(
                        controller: yearsController,
                        label: 'Plant Age',
                        hint: 'Example: 2',
                        icon: Icons.calendar_month_rounded,
                        keyboardType:
                        TextInputType.number,
                        suffixText: 'years',
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // PRICE
                      // ==================================================

                      _buildTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: 'Example: 500',
                        icon: Icons.currency_rupee_rounded,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixText: '₹ ',
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // ACTION BUTTONS
                      // ==================================================

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () =>
                                  Navigator.pop(dialogContext),
                              style:
                              OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(13),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isSaving ||
                                  isPickingImage
                                  ? null
                                  : saveVariant,
                              icon: isSaving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons
                                    .add_circle_outline,
                              ),
                              label: Text(
                                isSaving
                                    ? 'Saving...'
                                    : 'Add Variant',
                              ),
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                AppTheme.primary,
                                foregroundColor:
                                Colors.white,
                                elevation: 0,
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
  // TEXT FIELD
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
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide:
              BorderSide.none,
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
                color:
                AppTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showValidationMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
        SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // VARIANT CARD
  // ============================================================

  Widget _buildVariantImage(
      Map<String, dynamic> variant,
      ) {
    final imageUrl = variant['imageUrl']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return _defaultVariantImage();
          },
          loadingBuilder: (
              context,
              child,
              loadingProgress,
              ) {
            if (loadingProgress == null) {
              return child;
            }

            return _defaultVariantImage(
              loading: true,
            );
          },
        ),
      );
    }

    return _defaultVariantImage();
  }

  Widget _defaultVariantImage({
    bool loading = false,
  }) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        )
            : const Icon(
          Icons.inventory_2_rounded,
          color: AppTheme.primary,
          size: 30,
        ),
      ),
    );
  }

  Widget _variantInfo(
      IconData icon,
      String text,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color:
          Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color:
            Colors.grey.shade600,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
      ThemeData theme,
      ) {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration:
            BoxDecoration(
              color: AppTheme.primary
                  .withAlpha(15),
              shape:
              BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color:
              AppTheme.primary,
              size: 38,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            'No variants found',
            style: theme
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Add the first variant for $_varietyName',
            textAlign:
            TextAlign.center,
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
    );
  }

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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(18),
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
                  color: AppTheme.primary.withAlpha(20),
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
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(
      Map<String, dynamic> variant,
      ) {
    final theme = Theme.of(context);

    final variantName =
        variant['name']?.toString() ?? 'Unnamed Variant';

    final weight =
        variant['weight']?.toString() ?? '';

    final years =
        variant['years']?.toString() ?? '';

    final price =
        variant['price']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        // ==========================================================
        // CLICK VARIANT
        // ==========================================================

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateVariantScreen(
                plantId: widget.plantId,
                plantName: widget.plantName,
                varietyId: _varietyId,
                varietyName: _varietyName,
                variant: variant,
              ),
            ),
          ).then((_) {
            // Refresh variants after returning
            _loadVariants();
          });
        },

        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.center,
              children: [

                // =================================================
                // VARIANT IMAGE
                // =================================================

                _buildVariantImage(variant),

                const SizedBox(width: 14),

                // =================================================
                // VARIANT DETAILS
                // =================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      // -------------------------------------------------
                      // VARIANT LABEL
                      // -------------------------------------------------

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                          AppTheme.primary.withAlpha(15),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_rounded,
                              size: 13,
                              color:
                              AppTheme.primary,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              'VARIANT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing: 0.7,
                                color:
                                AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 7),

                      // -------------------------------------------------
                      // VARIANT NAME
                      // -------------------------------------------------

                      Text(
                        variantName,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w700,
                          color: theme
                              .colorScheme
                              .onSurface,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // -------------------------------------------------
                      // WEIGHT + AGE
                      // -------------------------------------------------

                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [

                          if (weight.isNotEmpty)
                            _variantInfo(
                              Icons.scale_rounded,
                              '$weight kg',
                            ),

                          if (years.isNotEmpty)
                            _variantInfo(
                              Icons
                                  .calendar_month_rounded,
                              '$years ${years == '1' ? 'year' : 'years'}',
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // -------------------------------------------------
                      // PRICE
                      // -------------------------------------------------

                      if (price.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .currency_rupee_rounded,
                              size: 16,
                              color:
                              AppTheme.primary,
                            ),

                            const SizedBox(width: 3),

                            Text(
                              price,
                              style: theme
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                color:
                                AppTheme.primary,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // =================================================
                // ARROW
                // =================================================

                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                    AppTheme.primary.withAlpha(12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
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

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _isLoading
            ? null
            : _showAddVariantDialog,
        backgroundColor:
        AppTheme.primary,
        foregroundColor:
        Colors.white,
        elevation: 4,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Variant',
          style: TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                10,
              ),
              child: Row(
                children: [
                  Material(
                    color:
                    Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pop(
                            context,
                          ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        15,
                      ),
                      child: Ink(
                        width: 44,
                        height: 44,
                        decoration:
                        BoxDecoration(
                          color: theme
                              .colorScheme
                              .surface,
                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),
                          border:
                          Border.all(
                            color: Colors
                                .grey
                                .shade200,
                          ),
                        ),
                        child:
                        const Icon(
                          Icons
                              .arrow_back_ios_new_rounded,
                          color:
                          AppTheme
                              .primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Manage Variants',
                          style: theme
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                        const SizedBox(
                            height: 2),
                        Text(
                          '$_varietyName variants',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // PARENT CONTEXT
            // ==================================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                6,
                16,
                18,
              ),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color: theme
                      .colorScheme
                      .surface,
                  borderRadius:
                  BorderRadius
                      .circular(
                    22,
                  ),
                  border:
                  Border.all(
                    color: AppTheme
                        .primary
                        .withAlpha(
                      35,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme
                          .primary
                          .withAlpha(
                        8,
                      ),
                      blurRadius: 16,
                      offset:
                      const Offset(
                        0,
                        5,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                      _buildParentInfo(
                        icon: Icons.eco_rounded,
                        label:
                        'PARENT PLANT',
                        value:
                        widget.plantName,
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 54,
                      color: Colors
                          .grey
                          .shade200,
                    ),

                    Expanded(
                      child:
                      _buildParentInfo(
                        icon: Icons
                            .account_tree_rounded,
                        label:
                        'PARENT VARIETY',
                        value:
                        _varietyName,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // VARIANTS HEADING
            // ==================================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                10,
              ),
              child: Row(
                children: [
                  Text(
                    'VARIANTS',
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

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Container(
                      height: 1,
                      color:
                      Colors.grey.shade200,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    '${_variants.length}',
                    style: theme
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                      color:
                      AppTheme.primary,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // LIST
            // ==================================================

            Expanded(
              child: _isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : _variants.isEmpty
                  ? _buildEmptyState(
                theme,
              )
                  : RefreshIndicator(
                onRefresh:
                _loadVariants,
                child:
                ListView.separated(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    4,
                    16,
                    100,
                  ),
                  itemCount:
                  _variants.length,
                  separatorBuilder:
                      (_, __) =>
                  const SizedBox(
                    height: 10,
                  ),
                  itemBuilder:
                      (context,
                      index) {
                    return _buildVariantCard(
                      _variants[
                      index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
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