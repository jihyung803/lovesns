import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/decoration_service.dart';
import 'package:new_couple_app/models/decoration_item.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';
import 'package:new_couple_app/widgets/couple_room/room_view.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({Key? key}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  bool _isEditMode = false;
  bool _isInventoryOpen = false;
  DecorationCategory? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _loadData();
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
      if (!_isEditMode) {
        _isInventoryOpen = false;
      }
    });
  }
  
  void _toggleInventory() {
    setState(() {
      _isInventoryOpen = !_isInventoryOpen;
      _selectedCategory = null;
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Room' : 'Couple Room'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: _toggleInventory,
              tooltip: 'Open Inventory',
            ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'Save Changes' : 'Edit Room',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: _navigateToShop,
            tooltip: 'Shop',
          ),
        ],
      ),
      body: Column(
        children: [
          // Currency display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room Level: ${roomDecoration.roomLevel}',
                  style: AppTheme.captionStyle,
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accentColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${authService.currentUser?.currency ?? 0} Coins',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
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
                
                // Inventory panel (shown in edit mode)
                if (_isEditMode && _isInventoryOpen)
                  _buildInventoryPanel(purchasedItems),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInventoryPanel(List<DecorationItem> purchasedItems) {
    // Group items by category
    final Map<DecorationCategory, List<DecorationItem>> itemsByCategory = {};
    
    for (final item in purchasedItems) {
      if (!item.isPlaced || item.category == DecorationCategory.wallpaper || item.category == DecorationCategory.flooring) {
        if (itemsByCategory[item.category] == null) {
          itemsByCategory[item.category] = [];
        }
        itemsByCategory[item.category]!.add(item);
      }
    }
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Category tabs
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                children: DecorationCategory.values.map((category) {
                  final isSelected = category == _selectedCategory;
                  final hasItems = itemsByCategory[category]?.isNotEmpty ?? false;
                  
                  return GestureDetector(
                    onTap: hasItems ? () => _selectCategory(category) : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasItems ? Colors.grey.shade400 : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : hasItems ? Colors.black87 : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Item grid
            Expanded(
              child: _selectedCategory == null
                  ? const Center(child: Text('Select a category above'))
                  : itemsByCategory[_selectedCategory]?.isEmpty ?? true
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No ${_selectedCategory!.name} items in inventory'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _navigateToShop,
                                child: const Text('Go to Shop'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: itemsByCategory[_selectedCategory]?.length ?? 0,
                          itemBuilder: (context, index) {
                            final item = itemsByCategory[_selectedCategory]![index];
                            return _buildInventoryItem(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInventoryItem(DecorationItem item) {
    final decorationService = Provider.of<DecorationService>(context, listen: false);
    
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                item.imageUrl,
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                style: const TextStyle(fontSize: 10),
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
      feedback: Image.network(
        item.imageUrl,
        height: 80,
        width: 80,
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              item.imageUrl,
              height: 40,
              width: 40,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}