import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/post_service.dart';
import 'package:new_couple_app/services/story_service.dart';
import 'package:new_couple_app/models/post.dart';
import 'package:new_couple_app/models/story.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';
import 'package:new_couple_app/widgets/profile/profile_header.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _userPosts = [];
  List<Story> _userStories = [];
  bool _isLoadingPosts = false;
  bool _isLoadingStories = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserContent();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserContent() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;
    
    final postService = Provider.of<PostService>(context, listen: false);
    final storyService = Provider.of<StoryService>(context, listen: false);
    
    setState(() {
      _isLoadingPosts = true;
      _isLoadingStories = true;
    });
    
    try {
      _userPosts = await postService.getPostsByUser(authService.currentUser!.id);
    } catch (e) {
      print('Error loading posts: $e');
    } finally {
      setState(() {
        _isLoadingPosts = false;
      });
    }
    
    try {
      _userStories = await storyService.getStoriesByUser(authService.currentUser!.id);
    } catch (e) {
      print('Error loading stories: $e');
    } finally {
      setState(() {
        _isLoadingStories = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    await _loadUserContent();
  }
  
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings').then((_) => _refreshData());
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.error != null) {
      return ErrorDialog(message: authService.error!, onRetry: _refreshData);
    }
    
    if (authService.isLoading) {
      return const LoadingIndicator();
    }
    
    final user = authService.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Profile header
            ProfileHeader(
              username: user.username,
              profileImageUrl: user.profileImageUrl,
              postCount: _userPosts.length,
              currencyCount: user.currency,
              relationshipStartDate: user.relationshipStartDate,
              partnerId: user.partnerId,
            ),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Stories'),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Posts tab
                  _isLoadingPosts
                      ? const LoadingIndicator()
                      : _buildPostsGrid(),
                  
                  // Stories tab
                  _isLoadingStories
                      ? const LoadingIndicator()
                      : _buildStoriesGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPostsGrid() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet. Share something with your partner!',
          style: AppTheme.bodyStyle,
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        
        // If post has images, display the first one
        if (post.imageUrls.isNotEmpty) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post-detail',
                arguments: post.id,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                post.imageUrls.first,
                fit: BoxFit.cover,
              ),
            ),
          );
        } else {
          // If no images, display the text content
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post-detail',
                arguments: post.id,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(post.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
  
  Widget _buildStoriesGrid() {
    if (_userStories.isEmpty) {
      return const Center(
        child: Text(
          'No stories yet. Complete daily missions to add stories!',
          style: AppTheme.bodyStyle,
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(4.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _userStories.length,
      itemBuilder: (context, index) {
        final story = _userStories[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/story-view',
              arguments: story.id,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Story image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  story.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              
              // Mission label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    story.missionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Date indicator
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('MM/dd').format(story.createdAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}