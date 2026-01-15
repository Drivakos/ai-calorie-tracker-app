import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/models/parsed_food.dart';
import 'package:ai_calorie_tracker/services/usda_service.dart';

/// Bottom sheet for searching USDA food database
class UsdaSearchSheet extends StatefulWidget {
  final String initialQuery;
  final Function(UsdaFoodResult) onFoodSelected;

  const UsdaSearchSheet({
    super.key,
    this.initialQuery = '',
    required this.onFoodSelected,
  });

  @override
  State<UsdaSearchSheet> createState() => _UsdaSearchSheetState();

  /// Show the search sheet as a modal bottom sheet
  static Future<UsdaFoodResult?> show(
    BuildContext context, {
    String initialQuery = '',
  }) async {
    return showModalBottomSheet<UsdaFoodResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UsdaSearchSheet(
        initialQuery: initialQuery,
        onFoodSelected: (food) => Navigator.pop(context, food),
      ),
    );
  }
}

class _UsdaSearchSheetState extends State<UsdaSearchSheet> {
  final UsdaService _usdaService = UsdaService();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  List<UsdaFoodResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _search(widget.initialQuery);
    }
    
    // Auto-focus after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _usdaService.searchFoods(query, pageSize: 15);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.database,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USDA Food Database', style: theme.textTheme.h4),
                          Text(
                            'Search for accurate nutrition data',
                            style: theme.textTheme.muted,
                          ),
                        ],
                      ),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () => Navigator.pop(context),
                      child: Icon(LucideIcons.x, color: theme.colorScheme.foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search input
                ShadInput(
                  controller: _searchController,
                  focusNode: _focusNode,
                  placeholder: const Text('Search foods (e.g., chicken breast, apple)'),
                  leading: const Icon(LucideIcons.search, size: 16),
                  trailing: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _results = []);
                          },
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        )
                      : null,
                  onChanged: _onSearchChanged,
                  onSubmitted: _search,
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Searching USDA database...', style: theme.textTheme.muted),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isEmpty
                                  ? LucideIcons.search
                                  : LucideIcons.searchX,
                              size: 48,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Enter a food name to search'
                                  : 'No foods found',
                              style: theme.textTheme.muted,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: bottomPadding + 16,
                        ),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final food = _results[index];
                          return _FoodResultCard(
                            food: food,
                            theme: theme,
                            onTap: () => widget.onFoodSelected(food),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FoodResultCard extends StatelessWidget {
  final UsdaFoodResult food;
  final ShadThemeData theme;
  final VoidCallback onTap;

  const _FoodResultCard({
    required this.food,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.description,
                        style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (food.brandName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          food.brandName!,
                          style: theme.textTheme.muted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (food.dataType != null)
                  ShadBadge.outline(
                    child: Text(_getDataTypeLabel(food.dataType!)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Nutrition per 100g
            Row(
              children: [
                Text('Per 100g: ', style: theme.textTheme.muted),
                _buildMacroBadge('${food.caloriesPer100g.round()}', 'kcal', theme.colorScheme.primary),
                const SizedBox(width: 6),
                _buildMacroBadge('${food.proteinPer100g.round()}g', 'P', const Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                _buildMacroBadge('${food.carbsPer100g.round()}g', 'C', const Color(0xFFF97316)),
                const SizedBox(width: 6),
                _buildMacroBadge('${food.fatPer100g.round()}g', 'F', const Color(0xFFEF4444)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDataTypeLabel(String dataType) {
    switch (dataType) {
      case 'Branded':
        return 'Brand';
      case 'Survey (FNDDS)':
        return 'Survey';
      case 'SR Legacy':
        return 'USDA';
      case 'Foundation':
        return 'Foundation';
      default:
        return dataType.length > 10 ? dataType.substring(0, 10) : dataType;
    }
  }

  Widget _buildMacroBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            ' $label',
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
