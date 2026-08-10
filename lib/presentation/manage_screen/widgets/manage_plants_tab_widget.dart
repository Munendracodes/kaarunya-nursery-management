
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/realtime_database_repository.dart';
import '../../../theme/app_theme.dart';

class ManagePlantsTabWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> plant)? onPlantTap;

  const ManagePlantsTabWidget({
    super.key,
    this.onPlantTap,
  });

  @override
  ManagePlantsTabWidgetState createState() =>
      ManagePlantsTabWidgetState();
}

@override
ManagePlantsTabWidgetState createState() =>
ManagePlantsTabWidgetState();


// Public State class so ManageScreen can access
// showAddPlantDialog() through GlobalKey.
class ManagePlantsTabWidgetState
extends State<ManagePlantsTabWidget> {
String _query = '';
String _selectedCategory = 'All';

List<Map<String, dynamic>> _plants = [];
List<String> _categories = ['All'];

bool _isLoading = true;

@override
void initState() {
super.initState();
_loadData();
}

// ------------------------------------------------------------
// LOAD PLANTS
// ------------------------------------------------------------

Future<void> _loadData() async {
if (mounted) {
setState(() {
_isLoading = true;
});
}

try {
final plants =
await RealtimeDatabaseRepository.instance.getPlants();

if (mounted) {
setState(() {
_plants = plants;
_categories = ['All'];
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
content: Text(
'Unable to load plants: $e',
),
),
);
}
}
}

// ------------------------------------------------------------
// FILTER PLANTS
// ------------------------------------------------------------

List<Map<String, dynamic>> get _filtered {
return _plants.where((plant) {
final plantName =
plant['name']?.toString() ?? '';

final categoryName =
plant['categoryId']?.toString() ?? '';

final matchesCategory =
_selectedCategory == 'All' ||
plantName.contains(_selectedCategory) ||
categoryName == _selectedCategory;

final matchesSearch =
_query.isEmpty ||
plantName
    .toLowerCase()
    .contains(_query.toLowerCase());

return matchesCategory && matchesSearch;
}).toList();
}

// ------------------------------------------------------------
// TOGGLE ACTIVE STATUS
// ------------------------------------------------------------


// ------------------------------------------------------------
// PUBLIC METHOD
//
// ManageScreen calls this method through GlobalKey.
// ------------------------------------------------------------

  void showAddPlantDialog() {
    final nameCtrl = TextEditingController();

    XFile? selectedImage;
    bool isSaving = false;
    bool isPickingImage = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // --------------------------------------------------
            // PICK IMAGE
            // --------------------------------------------------

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

                if (image != null && ctx.mounted) {
                  setDialogState(() {
                    selectedImage = image;
                  });
                }
              } catch (e, stackTrace) {
                debugPrint('Image picker error: $e');
                debugPrintStack(stackTrace: stackTrace);

                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        source == ImageSource.camera
                            ? 'Unable to open camera. Please check camera permission.'
                            : 'Unable to select image. Please check photo permissions.',
                      ),
                    ),
                  );
                }
              } finally {
                if (ctx.mounted) {
                  setDialogState(() {
                    isPickingImage = false;
                  });
                }
              }
            }

            // --------------------------------------------------
            // IMAGE SOURCE SELECTION
            // --------------------------------------------------

            Future<void> showImageSourceOptions() async {
              if (isSaving || isPickingImage) return;

              await showModalBottomSheet<void>(
                context: ctx,
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
                              'Add Plant Image',
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
                              'Choose how you want to add the plant image.',
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
            // SAVE PLANT
            // --------------------------------------------------

            Future<void> savePlant() async {
              final name = nameCtrl.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Please enter plant name',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final plantId =
                await RealtimeDatabaseRepository.instance.addPlant(
                  name: name,
                  image: selectedImage,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }

                await _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Plant added successfully',
                      ),
                    ),
                  );
                }

                debugPrint(
                  'Plant created successfully: $plantId',
                );
              } catch (e, stackTrace) {
                debugPrint('Failed to add plant: $e');
                debugPrintStack(stackTrace: stackTrace);

                if (ctx.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Failed to add plant: $e',
                      ),
                    ),
                  );
                }
              }
            }

            // --------------------------------------------------
            // ADD PLANT DIALOG
            // --------------------------------------------------

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
                      // ------------------------------------------------
                      // HEADER
                      // ------------------------------------------------

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
                              Icons.eco_rounded,
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
                                  'Add New Plant',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Add a plant to your nursery',
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
                                : () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // ------------------------------------------------
                      // PLANT NAME
                      // ------------------------------------------------

                      Text(
                        'Plant Information',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: nameCtrl,
                        enabled: !isSaving,
                        textCapitalization:
                        TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Example: Mango',
                          prefixIcon: const Icon(
                            Icons.eco_outlined,
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

                      const SizedBox(height: 26),

                      // ------------------------------------------------
                      // IMAGE SECTION
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plant Image',
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

                      // ------------------------------------------------
                      // IMAGE PREVIEW
                      // ------------------------------------------------

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
                              width:
                              selectedImage != null
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
                                decoration:
                                BoxDecoration(
                                  color: AppTheme
                                      .primary
                                      .withAlpha(20),
                                  shape:
                                  BoxShape.circle,
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
                                'Add Plant Image',
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
                                textAlign:
                                TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius
                                      .circular(20),
                                ),
                                child: const Text(
                                  'Tap to select',
                                  style: TextStyle(
                                    color:
                                    AppTheme.primary,
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
                                BorderRadius.circular(
                                  17,
                                ),
                                child: Image.file(
                                  File(
                                    selectedImage!.path,
                                  ),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Dark gradient overlay
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration:
                                  BoxDecoration(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      17,
                                    ),
                                    gradient:
                                    LinearGradient(
                                      begin: Alignment
                                          .topCenter,
                                      end: Alignment
                                          .bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withAlpha(
                                            140),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Change image button
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Material(
                                  color: Colors.black
                                      .withAlpha(130),
                                  borderRadius:
                                  BorderRadius.circular(
                                    12,
                                  ),
                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      12,
                                    ),
                                    onTap: isSaving ||
                                        isPickingImage
                                        ? null
                                        : showImageSourceOptions,
                                    child: const Padding(
                                      padding:
                                      EdgeInsets.all(
                                        10,
                                      ),
                                      child: Icon(
                                        Icons
                                            .edit_rounded,
                                        color:
                                        Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // File name
                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 12,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .check_circle_rounded,
                                      color:
                                      Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(
                                      width: 7,
                                    ),
                                    Expanded(
                                      child: Text(
                                        selectedImage!
                                            .name,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                        style:
                                        const TextStyle(
                                          color:
                                          Colors.white,
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



                      // ------------------------------------------------
                      // ACTION BUTTONS
                      // ------------------------------------------------

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () =>
                                  Navigator.pop(ctx),
                              style:
                              OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    13,
                                  ),
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
                              onPressed:
                              isSaving ||
                                  isPickingImage
                                  ? null
                                  : savePlant,
                              icon: isSaving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                  Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons
                                    .add_circle_outline,
                              ),
                              label: Text(
                                isSaving
                                    ? 'Saving...'
                                    : 'Add Plant',
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
                                  BorderRadius.circular(
                                    13,
                                  ),
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

// ------------------------------------------------------------
// BUILD
// ------------------------------------------------------------

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

  Widget _buildPlantCard(
      BuildContext context,
      Map<String, dynamic> plant,
      ) {
    final theme = Theme.of(context);

    final plantName =
    plant['name']?.toString().trim().isNotEmpty == true
        ? plant['name'].toString()
        : 'Unnamed Plant';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onPlantTap?.call(plant);
        },
        borderRadius: BorderRadius.circular(22),
        splashColor: AppTheme.primary.withAlpha(15),
        highlightColor: AppTheme.primary.withAlpha(8),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ==================================================
                // PLANT IMAGE
                // ==================================================

                Hero(
                  tag: 'plant-image-${plant['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 82,
                      height: 82,
                      child: _buildPlantImage(
                        plant,
                        size: 82,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ==================================================
                // PLANT DETAILS
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      // Small label
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'PLANT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      // Plant name
                      Text(
                        plantName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // Manage text
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Tap to manage',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ==================================================
                // NAVIGATION BUTTON
                // ==================================================

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.primary,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Column(
children: [
// ------------------------------------------------------
// SEARCH
// ------------------------------------------------------

Padding(
padding:
const EdgeInsets.fromLTRB(
16,
12,
16,
0,
),

child: TextFormField(
onChanged: (value) {
setState(() {
_query = value;
});
},

decoration:
const InputDecoration(
hintText: 'Search plants...',

prefixIcon: Icon(
Icons.search_rounded,
),

isDense: true,
),
),
),
SizedBox(height: 10),

// ------------------------------------------------------
// PLANT LIST
// ------------------------------------------------------

Expanded(
child: _isLoading
? const Center(
child:
CircularProgressIndicator(),
)
    : _filtered.isEmpty
? Center(
child: Column(
mainAxisSize:
MainAxisSize.min,

children: [
Icon(
Icons.eco_rounded,

size: 48,

color:
AppTheme.primaryLight,
),

const SizedBox(
height: 12,
),

Text(
'No plants found',

style: theme
    .textTheme
    .bodyLarge,
),

const SizedBox(
height: 8,
),

// ------------------------------------
// ADD PLANT BUTTON INSIDE EMPTY LIST
// ------------------------------------

ElevatedButton.icon(
onPressed:
showAddPlantDialog,

icon:
const Icon(
Icons.add,
),

label:
const Text(
'Add Plant',
),

style:
ElevatedButton
    .styleFrom(
backgroundColor:
AppTheme
    .primary,

foregroundColor:
Colors.white,
),
),
],
),
)
    : RefreshIndicator(
onRefresh:
_loadData,

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
_filtered.length,

separatorBuilder:
(_, __) =>
const SizedBox(
height: 10,
),

  itemBuilder: (context, index) {
    final plant = _filtered[index];

    return _buildPlantCard(
      context,
      plant,
    );
  },
),
),
),
],
);
}

// ------------------------------------------------------------
// PLANT IMAGE WIDGET
// ------------------------------------------------------------
  Widget _buildPlantImage(
      Map<String, dynamic> plant, {
        double size = 52,
      }) {
    final imageUrl = plant['imageUrl']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _defaultPlantIcon(size);
          },
          loadingBuilder: (
              context,
              child,
              loadingProgress,
              ) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return _defaultPlantIcon(size);
  }

  Widget _defaultPlantIcon([
    double size = 52,
  ]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        Icons.eco_rounded,
        color: AppTheme.primary,
        size: size * 0.42,
      ),
    );
  }
}

