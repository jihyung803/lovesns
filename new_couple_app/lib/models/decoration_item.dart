enum DecorationCategory {
  furniture,
  wallpaper,
  flooring,
  plant,
  pet,
  accessory,
  light,
  seasonal
}

extension DecorationCategoryExtension on DecorationCategory {
  String get name {
    switch (this) {
      case DecorationCategory.furniture:
        return 'Furniture';
      case DecorationCategory.wallpaper:
        return 'Wallpaper';
      case DecorationCategory.flooring:
        return 'Flooring';
      case DecorationCategory.plant:
        return 'Plants';
      case DecorationCategory.pet:
        return 'Pets';
      case DecorationCategory.accessory:
        return 'Accessories';
      case DecorationCategory.light:
        return 'Lights';
      case DecorationCategory.seasonal:
        return 'Seasonal';
    }
  }
}

class DecorationItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final DecorationCategory category;
  final bool isLimited;
  final DateTime? availableUntil;
  final bool isAnimated;
  final Map<String, dynamic> attributes; // Custom attributes like size, position, etc.
  final bool isPurchased;
  final bool isPlaced;

  DecorationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isLimited = false,
    this.availableUntil,
    this.isAnimated = false,
    this.attributes = const {},
    this.isPurchased = false,
    this.isPlaced = false,
  });

  factory DecorationItem.fromJson(Map<String, dynamic> json) {
    return DecorationItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      imageUrl: json['imageUrl'] as String,
      category: DecorationCategory.values[json['category'] as int],
      isLimited: json['isLimited'] as bool? ?? false,
      availableUntil: json['availableUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['availableUntil'] as int)
          : null,
      isAnimated: json['isAnimated'] as bool? ?? false,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      isPurchased: json['isPurchased'] as bool? ?? false,
      isPlaced: json['isPlaced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category.index,
      'isLimited': isLimited,
      'availableUntil': availableUntil?.millisecondsSinceEpoch,
      'isAnimated': isAnimated,
      'attributes': attributes,
      'isPurchased': isPurchased,
      'isPlaced': isPlaced,
    };
  }

  DecorationItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? imageUrl,
    DecorationCategory? category,
    bool? isLimited,
    DateTime? availableUntil,
    bool? isAnimated,
    Map<String, dynamic>? attributes,
    bool? isPurchased,
    bool? isPlaced,
  }) {
    return DecorationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isLimited: isLimited ?? this.isLimited,
      availableUntil: availableUntil ?? this.availableUntil,
      isAnimated: isAnimated ?? this.isAnimated,
      attributes: attributes ?? this.attributes,
      isPurchased: isPurchased ?? this.isPurchased,
      isPlaced: isPlaced ?? this.isPlaced,
    );
  }
}

class RoomDecoration {
  final String coupleId;
  final List<PlacedItem> placedItems;
  final String wallpaperId;
  final String flooringId;
  final int roomLevel;

  RoomDecoration({
    required this.coupleId,
    this.placedItems = const [],
    required this.wallpaperId,
    required this.flooringId,
    this.roomLevel = 1,
  });

  factory RoomDecoration.fromJson(Map<String, dynamic> json) {
    return RoomDecoration(
      coupleId: json['coupleId'] as String,
      placedItems: (json['placedItems'] as List<dynamic>?)
          ?.map((e) => PlacedItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      wallpaperId: json['wallpaperId'] as String,
      flooringId: json['flooringId'] as String,
      roomLevel: json['roomLevel'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coupleId': coupleId,
      'placedItems': placedItems.map((item) => item.toJson()).toList(),
      'wallpaperId': wallpaperId,
      'flooringId': flooringId,
      'roomLevel': roomLevel,
    };
  }

  RoomDecoration copyWith({
    String? coupleId,
    List<PlacedItem>? placedItems,
    String? wallpaperId,
    String? flooringId,
    int? roomLevel,
  }) {
    return RoomDecoration(
      coupleId: coupleId ?? this.coupleId,
      placedItems: placedItems ?? this.placedItems,
      wallpaperId: wallpaperId ?? this.wallpaperId,
      flooringId: flooringId ?? this.flooringId,
      roomLevel: roomLevel ?? this.roomLevel,
    );
  }
}

class PlacedItem {
  final String itemId;
  final double x;
  final double y;
  final double rotation;
  final double scale;
  final int zIndex;
  final DateTime placedAt;
  final String placedByUserId;

  PlacedItem({
    required this.itemId,
    required this.x,
    required this.y,
    this.rotation = 0.0,
    this.scale = 1.0,
    required this.zIndex,
    required this.placedAt,
    required this.placedByUserId,
  });

  factory PlacedItem.fromJson(Map<String, dynamic> json) {
    return PlacedItem(
      itemId: json['itemId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['zIndex'] as int,
      placedAt: DateTime.fromMillisecondsSinceEpoch(json['placedAt'] as int),
      placedByUserId: json['placedByUserId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'x': x,
      'y': y,
      'rotation': rotation,
      'scale': scale,
      'zIndex': zIndex,
      'placedAt': placedAt.millisecondsSinceEpoch,
      'placedByUserId': placedByUserId,
    };
  }
}