import 'package:flutter/material.dart';
import 'package:new_couple_app/models/decoration_item.dart';

class RoomView extends StatefulWidget {
  final RoomDecoration roomDecoration;
  final List<DecorationItem> purchasedItems;
  final bool isEditMode;
  final Function(DecorationItem item, Offset position)? onItemPlaced;
  final Function(String itemId)? onItemRemoved;

  const RoomView({
    Key? key,
    required this.roomDecoration,
    required this.purchasedItems,
    this.isEditMode = false,
    this.onItemPlaced,
    this.onItemRemoved,
  }) : super(key: key);

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  // Find the image URL from the purchased items
  String _getImageUrlForItem(String itemId) {
    final item = widget.purchasedItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => DecorationItem(
        id: 'default',
        name: 'Default',
        description: 'Default item',
        price: 0,
        imageUrl: 'https://via.placeholder.com/100',
        category: DecorationCategory.accessory,
      ),
    );
    
    return item.imageUrl;
  }
  
  // Get the wallpaper and flooring image URLs
  String _getWallpaperUrl() {
    return _getImageUrlForItem(widget.roomDecoration.wallpaperId);
  }
  
  String _getFlooringUrl() {
    return _getImageUrlForItem(widget.roomDecoration.flooringId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Room background
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(_getWallpaperUrl()),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        
        // Room floor
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.3,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_getFlooringUrl()),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        
        // Placed items
        ..._buildPlacedItems(),
        
        // Drop target for draggable items (only visible in edit mode)
        if (widget.isEditMode)
          DragTarget<DecorationItem>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              );
            },
            onAccept: (item) {
              if (widget.onItemPlaced != null) {
                // Calculate the position based on where it was dropped
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final Offset localPosition = renderBox.globalToLocal(
                  Offset(
                    MediaQuery.of(context).size.width / 2,
                    MediaQuery.of(context).size.height / 2,
                  ),
                );
                
                widget.onItemPlaced!(item, localPosition);
              }
            },
          ),
      ],
    );
  }
  
  List<Widget> _buildPlacedItems() {
    final List<Widget> itemWidgets = [];
    
    // Sort by z-index
    final sortedItems = List<PlacedItem>.from(widget.roomDecoration.placedItems)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    
    for (final placedItem in sortedItems) {
      // Find the item from the purchased items
      final item = widget.purchasedItems.firstWhere(
        (item) => item.id == placedItem.itemId,
        orElse: () => DecorationItem(
          id: 'default',
          name: 'Default',
          description: 'Default item',
          price: 0,
          imageUrl: 'https://via.placeholder.com/100',
          category: DecorationCategory.accessory,
        ),
      );
      
      itemWidgets.add(
        Positioned(
          left: placedItem.x,
          top: placedItem.y,
          child: Transform.rotate(
            angle: placedItem.rotation,
            child: Transform.scale(
              scale: placedItem.scale,
              child: GestureDetector(
                onTap: widget.isEditMode
                    ? () => _showItemOptions(context, placedItem)
                    : null,
                child: Image.network(
                  item.imageUrl,
                  width: 100, // Default size
                  height: 100, // Default size
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return itemWidgets;
  }
  
  void _showItemOptions(BuildContext context, PlacedItem placedItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Item Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Remove Item'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onItemRemoved != null) {
                    widget.onItemRemoved!(placedItem.itemId);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}