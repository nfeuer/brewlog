import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drink_recipe.dart';
import '../providers/drink_recipes_provider.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import 'share_drink_recipe_screen.dart';
import 'scan_qr_screen.dart';

class DrinkRecipeBookScreen extends ConsumerStatefulWidget {
  const DrinkRecipeBookScreen({super.key});

  @override
  ConsumerState<DrinkRecipeBookScreen> createState() => _DrinkRecipeBookScreenState();
}

class _DrinkRecipeBookScreenState extends ConsumerState<DrinkRecipeBookScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DrinkRecipe> _getFilteredRecipes() {
    final recipes = ref.watch(drinkRecipesProvider);
    if (_searchQuery.isEmpty) {
      return recipes;
    }
    return recipes
        .where((recipe) =>
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showDeleteConfirmation(BuildContext context, DrinkRecipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(drinkRecipesProvider.notifier)
                  .deleteRecipe(recipe.id);
              if (mounted) {
                Navigator.pop(context);
                showSuccess(context, 'Recipe deleted');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _getFilteredRecipes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drink Recipe Book'),
        backgroundColor: AppTheme.primaryBrown,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScanQRScreen(),
            ),
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Import Recipe'),
        backgroundColor: AppTheme.primaryBrown,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search recipes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Recipes list
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.menu_book_outlined
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No saved recipes yet'
                              : 'No recipes found',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Create recipes when making cups',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: recipes.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return _RecipeCard(
                        recipe: recipe,
                        onDelete: () => _showDeleteConfirmation(context, recipe),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends ConsumerStatefulWidget {
  final DrinkRecipe recipe;
  final VoidCallback onDelete;

  const _RecipeCard({
    required this.recipe,
    required this.onDelete,
  });

  @override
  ConsumerState<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<_RecipeCard> {
  bool _isExpanded = false;

  void _showEditNameDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.recipe.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Recipe Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Recipe Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                showError(context, 'Recipe name cannot be empty');
                return;
              }

              // Update recipe name
              final updatedRecipe = DrinkRecipe(
                id: widget.recipe.id,
                userId: widget.recipe.userId,
                name: nameController.text.trim(),
                baseType: widget.recipe.baseType,
                espressoShot: widget.recipe.espressoShot,
                milkType: widget.recipe.milkType,
                milkAmountMl: widget.recipe.milkAmountMl,
                ice: widget.recipe.ice,
                syrups: widget.recipe.syrups,
                sweeteners: widget.recipe.sweeteners,
                otherAdditions: widget.recipe.otherAdditions,
                instructions: widget.recipe.instructions,
                createdAt: widget.recipe.createdAt,
                updatedAt: DateTime.now(),
                usageCount: widget.recipe.usageCount,
              );

              await ref
                  .read(drinkRecipesProvider.notifier)
                  .updateRecipe(updatedRecipe);

              if (mounted) {
                Navigator.pop(context);
                showSuccess(context, 'Recipe name updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.local_cafe, color: AppTheme.primaryBrown),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.recipe.usageCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.recipe.usageCount}×',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              widget.recipe.summary,
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons at the top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShareDrinkRecipeScreen(
                                recipe: widget.recipe,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBrown,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showEditNameDialog(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Name'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.recipe.baseType != null) ...[
                    _buildDetailRow(
                      'Base Type',
                      widget.recipe.espressoShot != null
                          ? '${widget.recipe.espressoShot} ${widget.recipe.baseType}'
                          : widget.recipe.baseType!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.recipe.milkType != null) ...[
                    _buildDetailRow(
                      'Milk',
                      widget.recipe.milkAmountMl != null
                          ? '${widget.recipe.milkType} (${widget.recipe.milkAmountMl!.toInt()}ml)'
                          : widget.recipe.milkType!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.recipe.ice) ...[
                    _buildDetailRow('Preparation', 'Iced'),
                    const SizedBox(height: 8),
                  ],
                  if (widget.recipe.syrups.isNotEmpty) ...[
                    _buildDetailRow('Syrups', widget.recipe.syrups.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (widget.recipe.sweeteners.isNotEmpty) ...[
                    _buildDetailRow('Sweeteners', widget.recipe.sweeteners.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (widget.recipe.otherAdditions.isNotEmpty) ...[
                    _buildDetailRow('Additions', widget.recipe.otherAdditions.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (widget.recipe.instructions != null &&
                      widget.recipe.instructions!.isNotEmpty) ...[
                    const Text(
                      'Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.recipe.instructions!),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBrown,
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
