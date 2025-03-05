import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/decoration_service.dart';
import 'package:new_couple_app/models/decoration_item.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';

class DecorationShopScreen extends StatefulWidget {
  const DecorationShopScreen({Key? key}) : super(key: key);

  @override
  State<DecorationShopScreen> createState() => _DecorationShopScreenState();
}

class _DecorationShopScreenState extends State<DecorationShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DecorationCategory _selectedCategory = DecorationCategory.furniture;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: DecorationCategory.values.length,
      vsync: this,
    );
    
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = DecorationCategory.values[_tabController.index];
      });
    });
    
    _loadShopItems();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadShopItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final decorationService = Provider.of<DecorationService>(context, listen: false);
      
      // Load shop items
      await decorationService.loadShopItems();
      
      // Load purchased items to know what the user already owns
      await decorationService.loadPurchasedItems();
    } catch (e) {
      print('Error loading shop items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    await _loadShopItems();
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final decorationService = Provider.of<DecorationService>(context);
    
    if (decorationService.error != null) {
      return ErrorDialog(message: decorationService.error!, onRetry: _refreshData);
    }
    
    if (_isLoading || decorationService.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading shop items...'),
      );
    }
    
    // Filter items by category and remove already purchased items
    final List<DecorationItem> availableItems = decorationService.shopItems
        .where((item) => !decorationService.purchasedItems.any((purchased) => purchased.id == item.id))
        .toList();
    
    final Map<DecorationCategory, List<DecorationItem>> itemsByCategory = {};
    
    for (final category in DecorationCategory.values) {
      itemsByCategory[category] = availableItems
          .where((item) => item.category == category)
          .toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decoration Shop'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: DecorationCategory.values.map((category) {
            return Tab(text: category.name);
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Currency display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${authService.currentUser?.currency ?? 0} Coins',
                  style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Shop items
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: DecorationCategory.values.map((category) {
                final items = itemsByCategory[category] ?? [];
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${category.name} items available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new items!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildShopItem(context, item);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShopItem(BuildContext context, DecorationItem item) {
    final authService = Provider.of<AuthService>(context);
    final decorationService = Provider.of<DecorationService>(context);
    
    final bool canAfford = (authService.currentUser?.currency ?? 0) >= item.price;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Item details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Price
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: AppTheme.accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Purchase button
                    ElevatedButton(
                      onPressed: canAfford ? () => _purchaseItem(item) : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        minimumSize: const Size(60, 30),
                        backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey.shade400,
                      ),
                      child: const Text(
                        'Buy',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _purchaseItem(DecorationItem item) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final decorationService = Provider.of<DecorationService>(context, listen: false);
      final bool success = await decorationService.purchaseItem(item.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully purchased ${item.name}!')),
        );
        
        // Refresh the shop items
        await _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to purchase: ${decorationService.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to purchase: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}