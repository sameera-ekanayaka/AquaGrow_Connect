import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/crop_recipe.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_rows.dart';
import 'package:aquagrow_mobile/features/crops/domain/crop_recipes.dart';
import 'package:aquagrow_mobile/features/crops/presentation/delete_pod.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens "Choose a crop" for the empty [pod] and plants the crop the user
/// picks (Figma "Plant a crop"). Shows a snackbar when it is planted.
Future<void> showPlantCropSheet(BuildContext context, Pod pod) async {
  final crop = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.ag.background,
    builder: (_) => PlantCropSheet(pod: pod),
  );
  if (crop == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$crop planted in ${pod.name}')));
}

/// The list of crops to plant in [pod]. Pops with the crop name once planted.
class PlantCropSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for the empty [pod].
  const PlantCropSheet({required this.pod, super.key});

  /// The pod to plant in.
  final Pod pod;

  @override
  ConsumerState<PlantCropSheet> createState() => _PlantCropSheetState();
}

class _PlantCropSheetState extends ConsumerState<PlantCropSheet> {
  String? _planting;
  String? _error;

  Future<void> _plant(CropRecipe recipe) async {
    setState(() {
      _planting = recipe.cropName;
      _error = null;
    });
    try {
      await ref.read(podRepositoryProvider).plantCrop(widget.pod.id, recipe);
      ref.invalidate(podsProvider);
      if (mounted) Navigator.of(context).pop(recipe.cropName);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _planting = null;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    const recipes = CropRecipes.all;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AgSpace.s16,
            0,
            AgSpace.s16,
            AgSpace.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AgSpace.s8),
                child: Text('Choose a crop', style: text.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AgSpace.s8,
                  AgSpace.s4,
                  AgSpace.s8,
                  AgSpace.s12,
                ),
                child: Text(
                  '${widget.pod.name} will follow its recipe for pH, '
                  'nutrients and water.',
                  style: text.bodyMedium?.copyWith(color: c.textSecondary),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AgSpace.s8,
                    0,
                    AgSpace.s8,
                    AgSpace.s12,
                  ),
                  child: Text(
                    _error!,
                    style: text.bodyMedium?.copyWith(color: c.critical),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipes.length,
                  itemBuilder: (context, i) => _RecipeRow(
                    recipe: recipes[i],
                    busy: _planting == recipes[i].cropName,
                    onTap: _planting == null ? () => _plant(recipes[i]) : null,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _planting == null
                    ? () async {
                        if (await confirmDeletePod(context, ref, widget.pod) &&
                            context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                icon: Icon(Icons.delete_outline_rounded, color: c.critical),
                label: Text(
                  'Delete this pod',
                  style: TextStyle(color: c.critical),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One crop: photo, name, harvest time and pH range (Figma `RecipeRow`).
class _RecipeRow extends StatelessWidget {
  const _RecipeRow({
    required this.recipe,
    required this.busy,
    required this.onTap,
  });

  final CropRecipe recipe;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Plant ${recipe.cropName}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AgRadius.all(AgRadius.r20),
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.s8),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: CropPhoto(
                  radius: AgRadius.r16,
                  imageAsset: SupabaseRows.cropImage(recipe.cropName),
                ),
              ),
              const SizedBox(width: AgSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.cropName, style: text.titleMedium),
                    Text(
                      'Harvest in ${recipe.durationDays} days · '
                      'pH ${recipe.minPh}–${recipe.maxPh}',
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.add_circle_outline_rounded, color: c.text),
            ],
          ),
        ),
      ),
    );
  }
}
