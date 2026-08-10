import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/realtime_database_repository.dart';
import '../../../theme/app_theme.dart';
import 'manage_variant_screen.dart';



class ManagePlantScreen extends StatefulWidget {
  final Map<String, dynamic> plant;

  const ManagePlantScreen({
    super.key,
    required this.plant,
  });

  @override
  State<ManagePlantScreen> createState() =>
      _ManagePlantScreenState();
}

class _ManagePlantScreenState
    extends State<ManagePlantScreen> {
  List<Map<String, dynamic>> _varieties = [];

  bool _isLoading = true;

  String get _plantId =>
      widget.plant['id']?.toString() ?? '';

  String get _plantName =>
      widget.plant['name']?.toString() ?? 'Plant';

  String? get _plantImageUrl =>
      widget.plant['imageUrl']?.toString();

  @override
  void initState() {
    super.initState();
    _loadVarieties();
  }

  // ============================================================
  // LOAD VARIETIES
  // ============================================================

  Future<void> _loadVarieties() async {
    if (_plantId.isEmpty) {
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
      final varieties =
      await RealtimeDatabaseRepository.instance
          .getVarieties(_plantId);

      if (mounted) {
        setState(() {
          _varieties = varieties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Unable to load varieties: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // ADD VARIETY DIALOG
  // ============================================================

  void _showAddVarietyDialog() {
    final varietyNameController = TextEditingController();

    XFile? selectedImage;

    bool isSaving = false;
    bool isPickingImage = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            // --------------------------------------------------
            // PICK IMAGE
            // --------------------------------------------------

            Future<void> pickImage(
                ImageSource source,
                ) async {
              if (isSaving || isPickingImage) {
                return;
              }

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

                if (image != null) {
                  setDialogState(() {
                    selectedImage = image;
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
                if (context.mounted) {
                  setDialogState(() {
                    isPickingImage = false;
                  });
                }
              }
            }

            // --------------------------------------------------
            // IMAGE SOURCE OPTIONS
            // --------------------------------------------------

            Future<void> showImageSourceOptions() async {
              if (isSaving || isPickingImage) {
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                              'Add Variety Image',
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
                              'Choose how you want to add the variety image.',
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

            // --------------------------------------------------
            // SAVE VARIETY
            // --------------------------------------------------

            Future<void> saveVariety() async {
              final name = varietyNameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Please enter variety name',
                    ),
                  ),
                );

                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await RealtimeDatabaseRepository.instance.addVariety(
                  plantId: _plantId,
                  name: name,
                  image: selectedImage,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                await _loadVarieties();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Variety added successfully',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Failed to add variety: $e',
                      ),
                    ),
                  );
                }
              }
            }

            // ==================================================
            // DIALOG
            // ==================================================

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

            // ----------------------------------------
            // HEADER
            // ----------------------------------------

            Row(
            children: [
            Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
            Icons.account_tree_rounded,
            color: AppTheme.primary,
            size: 26,
            ),
            ),

            const SizedBox(width: 14),

            Expanded(
            child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
            Text(
            'Add New Variety',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
            fontWeight: FontWeight.w700,
            ),
            ),

            const SizedBox(height: 3),

            Text(
            'Add a variety to $_plantName',
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

            IconButton(
            onPressed: isSaving
            ? null
                : () => Navigator.pop(
            dialogContext,
            ),
            icon: const Icon(
            Icons.close_rounded,
            ),
            ),
            ],
            ),

            const SizedBox(height: 26),

            // ----------------------------------------
            // PLANT NAME - READ ONLY
            // ----------------------------------------

            Text(
            'Plant',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
            fontWeight: FontWeight.w700,
            ),
            ),

            const SizedBox(height: 10),

            Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
            ),
            decoration: BoxDecoration(
            color: AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
            color: Colors.grey.shade200,
            ),
            ),
            child: Row(
            children: [
            const Icon(
            Icons.eco_rounded,
            color: AppTheme.primary,
            ),

            const SizedBox(width: 10),

            Expanded(
            child: Text(
            _plantName,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
            fontWeight: FontWeight.w600,
            ),
            ),
            ),

            const Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: Colors.grey,
            ),
            ],
            ),
            ),

            const SizedBox(height: 22),

            // ----------------------------------------
            // VARIETY NAME
            // ----------------------------------------

            Text(
            'Variety Name',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
            fontWeight: FontWeight.w700,
            ),
            ),

            const SizedBox(height: 10),

            TextField(
            controller: varietyNameController,
            enabled: !isSaving,
            textCapitalization:
            TextCapitalization.words,
            decoration: InputDecoration(
            hintText: 'Example: Alphonso',
            prefixIcon: const Icon(
            Icons.local_florist_outlined,
            ),
            filled: true,
            fillColor:
            AppTheme.surfaceVariantLight,
            border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: BorderSide(
            color: Colors.grey.shade200,
            ),
            ),
            focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: const BorderSide(
            color: AppTheme.primary,
            width: 1.5,
            ),
            ),
            ),
            ),

            const SizedBox(height: 22),

            // ----------------------------------------
            // IMAGE
            // ----------------------------------------

            Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
            Text(
            'Variety Image',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
            fontWeight: FontWeight.w700,
            ),
            ),

            Text(
            'Optional',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
            color: Colors.grey.shade500,
            ),
            ),
            ],
            ),

            const SizedBox(height: 10),

            GestureDetector(
            onTap: isSaving || isPickingImage
            ? null
                : showImageSourceOptions,
            child: AnimatedContainer(
            duration:
            const Duration(milliseconds: 200),
            width: double.infinity,
            height: 190,
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
            color:
            AppTheme.primary,
            size: 30,
            ),
            ),

            const SizedBox(height: 12),

            Text(
            'Add Variety Image',
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
            ],
            )
                : Stack(
            children: [
            ClipRRect(
            borderRadius:
            BorderRadius.circular(17),
            child: Image.file(
            File(
            selectedImage!.path,
            ),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            ),
            ),

            Positioned(
            right: 12,
            top: 12,
            child: Material(
            color: Colors.black
                .withAlpha(130),
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
            style: const TextStyle(
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

            const SizedBox(height: 24),

            // ----------------------------------------
            // ACTIONS
            // ----------------------------------------

            Row(
            children: [
            Expanded(
            child: OutlinedButton(
            onPressed: isSaving
            ? null
                : () => Navigator.pop(
            dialogContext,
            ),
            style: OutlinedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(
            vertical: 14,
            ),
            shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(13),
            ),
            ),
            child: const Text(
            'Cancel',
            ),
            ),
            ),

            const SizedBox(width: 12),

            Expanded(
            flex: 2,
            child: ElevatedButton.icon(
            onPressed: isSaving ||
            isPickingImage
            ? null
                : saveVariety,
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
                : 'Add Variety',
            ),
            style: ElevatedButton.styleFrom(
            backgroundColor:
            AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
            const EdgeInsets.symmetric(
            vertical: 14,
            ),
            shape: RoundedRectangleBorder(
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
            ));
          },
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
                  color: AppTheme.primary
                      .withAlpha(20),
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
  // VARIETY CARD
  // ============================================================

  Widget _buildVarietyCard(
      Map<String, dynamic> variety,
      ) {
    final theme = Theme.of(context);

    final varietyName =
        variety['name']?.toString() ??
            'Unnamed Variety';

    final imageUrl =
    variety['imageUrl']?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageVariantScreen(
                plantId: _plantId,
                plantName: _plantName,
                variety: variety,
              ),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
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
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                // --------------------------------------------------
                // VARIETY IMAGE
                // --------------------------------------------------

                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(14),
                  child: imageUrl != null &&
                      imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                        _defaultVarietyIcon(),
                  )
                      : _defaultVarietyIcon(),
                ),

                const SizedBox(width: 14),

                // --------------------------------------------------
                // VARIETY DETAILS
                // --------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                          Colors.orange.withAlpha(18),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_tree_rounded,
                              size: 13,
                              color:
                              Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'VARIETY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing: 0.7,
                                color:
                                Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        varietyName,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            size: 14,
                            color:
                            AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$_plantName • Variety',
                              overflow:
                              TextOverflow.ellipsis,
                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color:
                                Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------
                // ARROW
                // --------------------------------------------------

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultVarietyIcon() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color:
        AppTheme.surfaceVariantLight,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.local_florist_rounded,
        color: AppTheme.primary,
        size: 32,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  Widget _buildPlantPlaceholder() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.eco_rounded,
        color: AppTheme.primary,
        size: 42,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
      AppTheme.backgroundLight,

      // --------------------------------------------------------
      // FAB
      // --------------------------------------------------------

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _isLoading
            ? null
            : _showAddVarietyDialog,
        backgroundColor:
        AppTheme.primary,
        foregroundColor:
        Colors.white,
        elevation: 4,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Variety',
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
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pop(context),
                      borderRadius:
                      BorderRadius.circular(
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
                          BorderRadius.circular(
                            15,
                          ),
                          border: Border.all(
                            color:
                            Colors.grey.shade200,
                          ),
                        ),
                        child:
                        const Icon(
                          Icons
                              .arrow_back_ios_new_rounded,
                          color:
                          AppTheme.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Manage Plant',
                          style: theme
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage varieties',
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
                ],
              ),
            ),

            // ==================================================
// SELECTED PLANT
// ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                6,
                16,
                18,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(18),
                            child: _plantImageUrl != null &&
                                _plantImageUrl!.isNotEmpty
                                ? Image.network(
                              _plantImageUrl!,
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlantPlaceholder(),
                            )
                                : _buildPlantPlaceholder(),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withAlpha(18),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.eco_rounded,
                                        color:
                                        AppTheme.primary,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'PARENT PLANT',
                                        style: theme
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                          color:
                                          AppTheme.primary,
                                          fontWeight:
                                          FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 9),

                                Text(
                                  _plantName,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: theme
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Plant',
                                  style: theme
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color:
                                    Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                        AppTheme.surfaceVariantLight,
                        borderRadius:
                        const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withAlpha(18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_tree_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            'Varieties',
                            style: theme
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            '${_varieties.length}',
                            style: theme
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: AppTheme.primary,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // VARIETY LIST
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                10,
              ),
              child: Row(
                children: [
                  Text(
                    'VARIETIES',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : _varieties.isEmpty
                  ? _buildEmptyState(
                theme,
              )
                  : RefreshIndicator(
                onRefresh:
                _loadVarieties,
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
                  _varieties.length,
                  separatorBuilder:
                      (_, __) =>
                  const SizedBox(
                    height: 10,
                  ),
                  itemBuilder:
                      (context, index) {
                    return _buildVarietyCard(
                      _varieties[index],
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
            decoration: BoxDecoration(
              color:
              AppTheme.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: AppTheme.primary,
              size: 38,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No varieties found',
            style: theme
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Add the first variety for $_plantName',
            textAlign: TextAlign.center,
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
}