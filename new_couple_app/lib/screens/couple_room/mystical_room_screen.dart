import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/decoration_service.dart';
import 'package:new_couple_app/models/decoration_item.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';
import 'package:new_couple_app/widgets/couple_room/room_view.dart';
import 'package:new_couple_app/widgets/couple_room/components/stars_background.dart';
import 'package:new_couple_app/widgets/couple_room/components/meteor_effect.dart';
import 'package:new_couple_app/widgets/couple_room/components/magical_inventory_panel.dart';

class MysticalRoomScreen extends StatefulWidget {
  const MysticalRoomScreen({Key? key}) : super(key: key);

  @override
  State<MysticalRoomScreen> createState() => _MysticalRoomScreenState();
}

class _MysticalRoomScreenState extends State<MysticalRoomScreen> with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  bool _isInventoryOpen = false;
  DecorationCategory? _selectedCategory;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final decorationService = Provider.of<DecorationService>(context, listen: false);
    
    await decorationService.loadRoomDecoration();
    await decorationService.loadPurchasedItems();
  }
  
  Future<void> _refreshData() async {
    await _loadData();
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      
      if (_isEditMode) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _isInventoryOpen = false;
      }
    });
  }
  
  void _toggleInventory() {
    setState(() {
      _isInventoryOpen = !_isInventoryOpen;
      if (_isInventoryOpen) {
        _selectedCategory = DecorationCategory.values.first;
      } else {
        _selectedCategory = null;
      }
    });
  }
  
  void _selectCategory(DecorationCategory category) {
    setState(() {
      _selectedCategory = category == _selectedCategory ? null : category;
    });
  }
  
  void _navigateToShop() {
    Navigator.pushNamed(context, '/decoration-shop').then((_) => _refreshData());
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final decorationService = Provider.of<DecorationService>(context);
    
    if (decorationService.error != null) {
      return ErrorDialog(message: decorationService.error!, onRetry: _refreshData);
    }
    
    if (decorationService.isLoading) {
      return const LoadingIndicator();
    }
    
    final roomDecoration = decorationService.roomDecoration;
    final purchasedItems = decorationService.purchasedItems;
    
    if (roomDecoration == null) {
      return const Center(child: Text('Room not initialized'));
    }
    
    // Group items by category for the inventory
    final Map<DecorationCategory, List<DecorationItem>> itemsByCategory = {};
    
    for (final item in purchasedItems) {
      if (!item.isPlaced || item.category == DecorationCategory.wallpaper || item.category == DecorationCategory.flooring) {
        if (itemsByCategory[item.category] == null) {
          itemsByCategory[item.category] = [];
        }
        itemsByCategory[item.category]!.add(item);
      }
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildMysticalAppBar(authService),
      ),
      body: Stack(
        children: [
          // Starry background
          const StarsBackground(
            starDensity: 0.0002,
            minTwinkleSpeed: 0.3,
            maxTwinkleSpeed: 1.5,
          ),
          
          // Meteor effect
          const MeteorEffect(
            number: 15,
            color: Colors.white,
          ),
          
          // Room decorations
          SafeArea(
            child: Column(
              children: [
                // Currency display
                _buildCurrencyDisplay(authService, roomDecoration),
                
                // Room view
                Expanded(
                  child: Stack(
                    children: [
                      // Room background and items
                      RoomView(
                        roomDecoration: roomDecoration,
                        purchasedItems: purchasedItems,
                        isEditMode: _isEditMode,
                        onItemPlaced: (item, position) {
                          decorationService.placeItem(
                            item.id,
                            position.dx,
                            position.dy,
                          );
                        },
                        onItemRemoved: (itemId) {
                          decorationService.removeItem(itemId);
                        },
                      ),
                      
                      // Edit mode overlay - showing glowing borders for draggable items
                      if (_isEditMode)
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(12),
                          ),
                        ),
                      
                      // Inventory panel (shown in edit mode)
                      if (_isEditMode && _isInventoryOpen)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: MagicalInventoryPanel(
                            itemsByCategory: itemsByCategory,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _selectCategory,
                            buildInventoryItem: (item) => _buildInventoryItem(item, decorationService),
                            onShopPressed: _navigateToShop,
                          ),
                        ),
                      
                      // Edit mode floating action buttons
                      if (_isEditMode)
                        Positioned(
                          bottom: _isInventoryOpen ? 270 : 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Shop button
                              _buildMagicalActionButton(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Shop',
                                color: Colors.amber,
                                onPressed: _navigateToShop,
                              ),
                              const SizedBox(height: 12),
                              
                              // Inventory button
                              _buildMagicalActionButton(
                                icon: Icons.inventory_2_outlined,
                                label: 'Inventory',
                                color: Colors.blueAccent,
                                onPressed: _toggleInventory,
                                isActive: _isInventoryOpen,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildEditModeButton(),
    );
  }
  
  Widget _buildMysticalAppBar(AuthService authService) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _isEditMode ? 'Edit Magical Space' : 'Couple\'s Sanctuary',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // Partner status
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Partner Online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrencyDisplay(AuthService authService, dynamic roomDecoration) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.2),
                Colors.indigo.withOpacity(0.2),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Room level
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                      shadows: [
                        Shadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Level ${roomDecoration.roomLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Currency display
              FutureBuilder<int>(
                future: authService.getCoupleCurrency(),
                builder: (context, snapshot) {
                  final currencyCount = snapshot.data ?? authService.currentUser?.currency ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          color: AppTheme.accentColor,
                          size: 16,
                          shadows: [
                            Shadow(
                              color: AppTheme.accentColor.withOpacity(0.7),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$currencyCount Gems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInventoryItem(DecorationItem item, DecorationService decorationService) {
    // For wallpaper and flooring, we show a different UI
    if (item.category == DecorationCategory.wallpaper || item.category == DecorationCategory.flooring) {
      return GestureDetector(
        onTap: () {
          if (item.category == DecorationCategory.wallpaper) {
            decorationService.updateRoomBackground(wallpaperId: item.id);
          } else {
            decorationService.updateRoomBackground(flooringId: item.id);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 44,
                width: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
    
    // For other items, make them draggable
    return LongPressDraggable<DecorationItem>(
      data: item,
      feedback: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.network(
          item.imageUrl,
          height: 80,
          width: 80,
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Icon(
            Icons.drag_indicator,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 44,
              width: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMagicalActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color.withOpacity(0.6) : Colors.white30,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEditModeButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FloatingActionButton(
          onPressed: _toggleEditMode,
          backgroundColor: _isEditMode
              ? Colors.white
              : AppTheme.primaryColor,
          foregroundColor: _isEditMode
              ? AppTheme.primaryColor
              : Colors.white,
          elevation: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Save icon
              AnimatedOpacity(
                opacity: _animationController.value,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.check),
              ),
              
              // Edit icon
              AnimatedOpacity(
                opacity: 1 - _animationController.value,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.edit),
              ),
            ],
          ),
        );
      },
    );
  }
}
