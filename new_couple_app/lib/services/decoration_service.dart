import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_couple_app/models/decoration_item.dart';
import 'package:new_couple_app/services/auth_service.dart';


class DecorationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  
  List<DecorationItem> _shopItems = [];
  List<DecorationItem> _purchasedItems = [];
  RoomDecoration? _roomDecoration;
  bool _isLoading = false;
  String? _error;
  
  List<DecorationItem> get shopItems => _shopItems;
  List<DecorationItem> get purchasedItems => _purchasedItems;
  RoomDecoration? get roomDecoration => _roomDecoration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  DecorationService({AuthService? authService})
      : _authService = authService ?? AuthService();
  
  Future<void> loadShopItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('decorationItems')
          .get();
      
      final List<DecorationItem> items = snapshot.docs
          .map((doc) => DecorationItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Filter out limited items that are no longer available
      _shopItems = items.where((item) {
        if (item.isLimited && item.availableUntil != null) {
          return DateTime.now().isBefore(item.availableUntil!);
        }
        return true;
      }).toList();
      
      // Sort items by category
      _shopItems.sort((a, b) => a.category.index.compareTo(b.category.index));
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadPurchasedItems() async {
    if (_authService.currentUser == null || _authService.currentUser!.coupleId == null) {
      _error = 'User not connected with a partner';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final coupleId = _authService.currentUser!.coupleId!;
      final QuerySnapshot snapshot = await _firestore
          .collection('purchasedItems')
          .where('coupleId', isEqualTo: coupleId)
          .get();
      
      final List<String> purchasedItemIds = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['itemId'] as String)
          .toList();
      
      // Get full item details for each purchased item
      _purchasedItems = [];
      for (final itemId in purchasedItemIds) {
        final DocumentSnapshot itemDoc = await _firestore
            .collection('decorationItems')
            .doc(itemId)
            .get();
        
        if (itemDoc.exists) {
          final DecorationItem item = DecorationItem.fromJson(
            itemDoc.data() as Map<String, dynamic>
          ).copyWith(isPurchased: true);
          
          _purchasedItems.add(item);
        }
      }
      
      // Sort items by category
      _purchasedItems.sort((a, b) => a.category.index.compareTo(b.category.index));
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadRoomDecoration() async {
    if (_authService.currentUser == null || _authService.currentUser!.coupleId == null) {
      _error = 'User not connected with a partner';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final coupleId = _authService.currentUser!.coupleId!;
      final DocumentSnapshot roomDoc = await _firestore
          .collection('rooms')
          .doc(coupleId)
          .get();
      
      if (roomDoc.exists) {
        _roomDecoration = RoomDecoration.fromJson(roomDoc.data() as Map<String, dynamic>);
      } else {
        // Create default room if it doesn't exist
        _roomDecoration = RoomDecoration(
          coupleId: coupleId,
          wallpaperId: 'default_wallpaper',
          flooringId: 'default_flooring',
        );
        
        await _firestore.collection('rooms').doc(coupleId).set(_roomDecoration!.toJson());
      }
      
      // Update purchased items to mark placed ones
      if (_roomDecoration != null && _purchasedItems.isNotEmpty) {
        final List<String> placedItemIds = _roomDecoration!.placedItems
            .map((item) => item.itemId)
            .toList();
        
        _purchasedItems = _purchasedItems.map((item) {
          return item.copyWith(isPlaced: placedItemIds.contains(item.id));
        }).toList();
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> purchaseItem(String itemId) async {
    if (_authService.currentUser == null || _authService.currentUser!.coupleId == null) {
      _error = 'User not connected with a partner';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find item in shop
      final int index = _shopItems.indexWhere((item) => item.id == itemId);
      if (index == -1) {
        _error = 'Item not found';
        return false;
      }
      
      final DecorationItem item = _shopItems[index];
      
      // Check if user has enough currency
      if (_authService.currentUser!.currency < item.price) {
        _error = 'Not enough currency to purchase this item';
        return false;
      }
      
      // Record purchase
      await _firestore.collection('purchasedItems').add({
        'coupleId': _authService.currentUser!.coupleId!,
        'itemId': itemId,
        'purchasedByUserId': _authService.currentUser!.id,
        'purchasedAt': DateTime.now().millisecondsSinceEpoch,
        'price': item.price,
      });
      
      // Deduct currency
      await _authService.updateCurrency(-item.price);
      
      // Add to purchased items
      final DecorationItem purchasedItem = item.copyWith(isPurchased: true);
      _purchasedItems.add(purchasedItem);
      
      // Sort items
      _purchasedItems.sort((a, b) => a.category.index.compareTo(b.category.index));
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> placeItem(String itemId, double x, double y, {double rotation = 0.0, double scale = 1.0}) async {
    if (_authService.currentUser == null || 
        _authService.currentUser!.coupleId == null || 
        _roomDecoration == null) {
      _error = 'Room not initialized';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if item is purchased
      final int index = _purchasedItems.indexWhere((item) => item.id == itemId);
      if (index == -1) {
        _error = 'Item not purchased';
        return false;
      }
      
      // Create placed item
      final PlacedItem newPlacedItem = PlacedItem(
        itemId: itemId,
        x: x,
        y: y,
        rotation: rotation,
        scale: scale,
        zIndex: _roomDecoration!.placedItems.length + 1,
        placedAt: DateTime.now(),
        placedByUserId: _authService.currentUser!.id,
      );
      
      // Add to room decoration
      final List<PlacedItem> updatedPlacedItems = [..._roomDecoration!.placedItems, newPlacedItem];
      
      // Update in Firestore
      await _firestore.collection('rooms').doc(_authService.currentUser!.coupleId).update({
        'placedItems': updatedPlacedItems.map((item) => item.toJson()).toList(),
      });
      
      // Update local room decoration
      _roomDecoration = _roomDecoration!.copyWith(placedItems: updatedPlacedItems);
      
      // Update purchased item to mark as placed
      _purchasedItems[index] = _purchasedItems[index].copyWith(isPlaced: true);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> removeItem(String itemId) async {
    if (_authService.currentUser == null || 
        _authService.currentUser!.coupleId == null || 
        _roomDecoration == null) {
      _error = 'Room not initialized';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find placed item index
      final int placedIndex = _roomDecoration!.placedItems.indexWhere((item) => item.itemId == itemId);
      if (placedIndex == -1) {
        _error = 'Item not found in room';
        return false;
      }
      
      // Remove from placed items
      final List<PlacedItem> updatedPlacedItems = List.from(_roomDecoration!.placedItems);
      updatedPlacedItems.removeAt(placedIndex);
      
      // Update z-index for remaining items
      for (int i = 0; i < updatedPlacedItems.length; i++) {
        updatedPlacedItems[i] = PlacedItem(
          itemId: updatedPlacedItems[i].itemId,
          x: updatedPlacedItems[i].x,
          y: updatedPlacedItems[i].y,
          rotation: updatedPlacedItems[i].rotation,
          scale: updatedPlacedItems[i].scale,
          zIndex: i + 1,
          placedAt: updatedPlacedItems[i].placedAt,
          placedByUserId: updatedPlacedItems[i].placedByUserId,
        );
      }
      
      // Update in Firestore
      await _firestore.collection('rooms').doc(_authService.currentUser!.coupleId).update({
        'placedItems': updatedPlacedItems.map((item) => item.toJson()).toList(),
      });
      
      // Update local room decoration
      _roomDecoration = _roomDecoration!.copyWith(placedItems: updatedPlacedItems);
      
      // Find purchased item index
      final int purchasedIndex = _purchasedItems.indexWhere((item) => item.id == itemId);
      if (purchasedIndex != -1) {
        // Update purchased item to mark as not placed
        _purchasedItems[purchasedIndex] = _purchasedItems[purchasedIndex].copyWith(isPlaced: false);
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateRoomBackground({String? wallpaperId, String? flooringId}) async {
    if (_authService.currentUser == null || 
        _authService.currentUser!.coupleId == null || 
        _roomDecoration == null) {
      _error = 'Room not initialized';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Prepare updates
      final Map<String, dynamic> updates = {};
      
      if (wallpaperId != null) {
        // Check if wallpaper is purchased
        final bool isWallpaperPurchased = _purchasedItems.any((item) => 
            item.id == wallpaperId && item.category == DecorationCategory.wallpaper);
        
        if (!isWallpaperPurchased && wallpaperId != 'default_wallpaper') {
          _error = 'Wallpaper not purchased';
          return false;
        }
        
        updates['wallpaperId'] = wallpaperId;
      }
      
      if (flooringId != null) {
        // Check if flooring is purchased
        final bool isFlooringPurchased = _purchasedItems.any((item) => 
            item.id == flooringId && item.category == DecorationCategory.flooring);
        
        if (!isFlooringPurchased && flooringId != 'default_flooring') {
          _error = 'Flooring not purchased';
          return false;
        }
        
        updates['flooringId'] = flooringId;
      }
      
      if (updates.isEmpty) {
        return true; // Nothing to update
      }
      
      // Update in Firestore
      await _firestore.collection('rooms').doc(_authService.currentUser!.coupleId).update(updates);
      
      // Update local room decoration
      _roomDecoration = _roomDecoration!.copyWith(
        wallpaperId: wallpaperId ?? _roomDecoration!.wallpaperId,
        flooringId: flooringId ?? _roomDecoration!.flooringId,
      );
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}