import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/models/decoration_item.dart';

class MagicalInventoryPanel extends StatelessWidget {
  final Map<DecorationCategory, List<DecorationItem>> itemsByCategory;
  final DecorationCategory? selectedCategory;
  final Function(DecorationCategory) onCategorySelected;
  final Widget Function(DecorationItem) buildInventoryItem;
  final VoidCallback onShopPressed;

  const MagicalInventoryPanel({
    Key? key,
    required this.itemsByCategory,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.buildInventoryItem,
    required this.onShopPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.indigo.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              // Header with pull indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Category tabs
              _buildCategoryTabs(),
              
              // Item grid
              Expanded(
                child: _buildItemGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: DecorationCategory.values.map((category) {
          final isSelected = category == selectedCategory;
          final hasItems = itemsByCategory[category]?.isNotEmpty ?? false;
          
          return GestureDetector(
            onTap: hasItems ? () => onCategorySelected(category) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.9),
                          const Color(0xFFF67789),
                        ],
                      )
                    : null,
                color: isSelected 
                    ? null 
                    : hasItems 
                        ? Colors.black45 
                        : Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                category.displayName,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : hasItems 
                          ? Colors.white.withOpacity(0.9) 
                          : Colors.white.withOpacity(0.4),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemGrid() {
    if (selectedCategory == null) {
      return Center(
        child: Text(
          'Select a category above',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    final items = itemsByCategory[selectedCategory];
    if (items == null || items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No ${selectedCategory!.name} items in inventory',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onShopPressed,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Go to Shop'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return buildInventoryItem(items[index]);
      },
    );
  }
}

// Helper extension for displaying category names
extension DecorationCategoryNameExtension on DecorationCategory {
  String get displayName {
    switch (this) {
      case DecorationCategory.furniture:
        return '🪑 Furniture';
      case DecorationCategory.wallpaper:
        return '🖼️ Wallpaper';
      case DecorationCategory.flooring:
        return '🧩 Flooring';
      case DecorationCategory.lighting:
        return '💡 Lighting';
      case DecorationCategory.plants:
        return '🌱 Plants';
      case DecorationCategory.decor:
        return '✨ Décor';
      case DecorationCategory.pet:
        return '🐱 Pets';
      default:
        return this.toString().split('.').last;
    }
  }
}
