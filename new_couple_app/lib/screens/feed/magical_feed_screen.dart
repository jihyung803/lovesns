import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/post_service.dart';
import 'package:new_couple_app/services/story_service.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';
import 'package:new_couple_app/widgets/feed/post_card.dart';
import 'package:new_couple_app/widgets/feed/story_bubble.dart';
import 'package:new_couple_app/models/story.dart';
import 'package:new_couple_app/models/post.dart';
import 'package:new_couple_app/services/notification_service.dart';
import 'package:share_plus/share_plus.dart';

class MagicalFeedScreen extends StatefulWidget {
  const MagicalFeedScreen({Key? key}) : super(key: key);

  @override
  State<MagicalFeedScreen> createState() => _MagicalFeedScreenState();
}

class _MagicalFeedScreenState extends State<MagicalFeedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load posts
    await Provider.of<PostService>(context, listen: false).loadPosts();
    
    // Load stories
    await Provider.of<StoryService>(context, listen: false).loadStories();
    
    // Load today's mission
    await Provider.of<StoryService>(context, listen: false).loadTodayMission();
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showCreatePostScreen() {
    Navigator.pushNamed(context, '/create-post').then((_) => _refreshData());
  }

  void _showCreateStoryScreen() {
    Navigator.pushNamed(context, '/create-story').then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final postService = Provider.of<PostService>(context);
    final storyService = Provider.of<StoryService>(context);
    
    if (authService.error != null) {
      return ErrorDialog(message: authService.error!, onRetry: _refreshData);
    }
    
    if (postService.error != null) {
      return ErrorDialog(message: postService.error!, onRetry: _refreshData);
    }
    
    if (storyService.error != null) {
      return ErrorDialog(message: storyService.error!, onRetry: _refreshData);
    }
    
    if (authService.isLoading || postService.isLoading || storyService.isLoading) {
      return const LoadingIndicator(message: 'Loading your cosmic memories...');
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildMagicalAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1F4A), // Deep purple
              Color(0xFF0F0A1F), // Almost black with a hint of purple
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppTheme.primaryColor,
            backgroundColor: Colors.deepPurple.shade800,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Stories section
                SliverToBoxAdapter(
                  child: _buildStoriesSection(storyService),
                ),
                
                // Posts section
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.pinkAccent,
                              Colors.purpleAccent,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Cosmic Memories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showCreatePostScreen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'New Memory',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Empty state or post list
                postService.posts.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = postService.posts[index];
                              // 애니메이션 효과 제거 (스크롤 시 흐려짐 개선)
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildMagicalPostCard(
                                  post: post,
                                  onLike: () => postService.likePost(post.id),
                                  onComment: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/post-detail',
                                      arguments: post.id,
                                    );
                                  },
                                  onDelete: () => postService.deletePost(post.id),
                                ),
                              );
                            },
                            childCount: postService.posts.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
      // FloatingActionButton 제거
    );
  }

  PreferredSizeWidget _buildMagicalAppBar() {
    final notificationService = Provider.of<NotificationService>(context);
    final isNotificationsEnabled = notificationService.notificationsEnabled;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.pinkAccent,
                Colors.purpleAccent,
                Colors.deepPurpleAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Celestial Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.auto_awesome,
            color: Colors.amber.withOpacity(0.8),
            size: 16,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isNotificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: isNotificationsEnabled ? Colors.amber.withOpacity(0.8) : Colors.white70,
          ),
          onPressed: () {
            notificationService.toggleNotifications();
            
            // 토스트 메시지 표시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isNotificationsEnabled ? 'Notifications disabled' : 'Notifications enabled',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: isNotificationsEnabled 
                  ? Colors.grey.shade800 
                  : AppTheme.primaryColor.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
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

  Widget _buildStoriesSection(StoryService storyService) {
    final todayMission = storyService.todayMission;
    final stories = storyService.stories;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Container(
        height: 123,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: Colors.amber.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Today\'s Quest',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: stories.isEmpty ? 1 : stories.length + 1,
                itemBuilder: (context, index) {
                  // First item is always the create story bubble
                  if (index == 0) {
                    return _buildMagicalStoryBubble(
                      isCreateBubble: true,
                      missionTitle: todayMission?.title ?? 'Daily Quest',
                      missionDescription: todayMission?.description ?? 'Embark on today\'s magical journey',
                      onTap: _showCreateStoryScreen,
                    );
                  }
                  
                  // Other items are existing stories
                  final story = stories[index - 1];
                  return _buildMagicalStoryBubble(
                    imageUrl: story.imageUrl,
                    isViewed: story.isViewed,
                    userName: 'User', // Fixed: Using default value since story.userName doesn't exist
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/story-view',
                        arguments: story.id,
                      ).then((_) => _refreshData());
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMagicalStoryBubble({
    bool isCreateBubble = false,
    String? imageUrl,
    bool isViewed = false,
    String? missionTitle,
    String? missionDescription,
    String? userName,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // Story bubble
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCreateBubble
                    ? LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.purple.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isCreateBubble ? Colors.purple : Colors.pinkAccent).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: isViewed ? Colors.white24 : Colors.pinkAccent,
                  width: 2,
                ),
              ),
              child: isCreateBubble
                  ? const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 30,
                    )
                  : ClipOval(
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                    ),
            ),
            const SizedBox(height: 4),
            
            // Text
            
          ],
        ),
      ),
    );
  }
  
  Widget _buildMagicalPostCard({
    required Post post,
    required VoidCallback onLike,
    required VoidCallback onComment,
    required VoidCallback onDelete,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // User avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent,
                            Colors.deepPurple,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'U', // Using first letter initial since post.userName doesn't exist
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // User name and post time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User', // Using default name since post.userName doesn't exist
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // More options button
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => _buildOptionsBottomSheet(post, onDelete),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Post content
              if (post.imageUrls.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Image.network(
                    post.imageUrls[0], // Use the first image in the list
                    fit: BoxFit.cover,
                  ),
                ),
              
              // Post text
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    post.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              // Post actions
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Row(
                  children: [
                    // Like button
                    _buildActionButton(
                      icon: post.isLikedByPartner ? Icons.favorite : Icons.favorite_border,
                      color: post.isLikedByPartner ? AppTheme.primaryColor : Colors.white70,
                      label: post.likeCount.toString(),
                      onPressed: onLike,
                    ),
                    const SizedBox(width: 16),
                    
                    // Comment button
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: post.comments.length.toString(),
                      onPressed: onComment,
                    ),
                    const Spacer(),
                    
                    // Share button
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        _sharePost(post);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white70,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionsBottomSheet(Post post, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1538),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            _buildOptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Memory',
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to edit post
              },
            ),
            const Divider(color: Colors.white12),
            _buildOptionTile(
              icon: Icons.copy_outlined,
              label: 'Copy Link',
              onTap: () {
                Navigator.of(context).pop();
                // Copy post link
              },
            ),
            const Divider(color: Colors.white12),
            _buildOptionTile(
              icon: Icons.bookmark_border_outlined,
              label: 'Save Memory',
              onTap: () {
                Navigator.of(context).pop();
                // Save post
              },
            ),
            const Divider(color: Colors.white12),
            _buildOptionTile(
              icon: Icons.delete_outline,
              label: 'Delete Memory',
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => _buildDeleteConfirmationDialog(onDelete),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
  
  Widget _buildDeleteConfirmationDialog(VoidCallback onDelete) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1538),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Memory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete this memory? This action cannot be undone.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                Icons.photo_album_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Cosmic Memories Yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first memory to begin your cosmic journey together',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreatePostScreen,
              icon: const Icon(Icons.add),
              label: const Text('Create First Memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                shadowColor: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCreatePostFAB() {
    return FloatingActionButton(
        onPressed: _showCreatePostScreen,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 10,
        child: const Icon(Icons.add_photo_alternate_rounded),
    );
  }
  
  // 포스트 공유 기능
  void _sharePost(Post post) {
    // 공유할 텍스트 생성
    String shareText = '';
    
    // 포스트 내용 추가
    if (post.content.isNotEmpty) {
      // 내용이 너무 길면 일부만 추가
      if (post.content.length > 100) {
        shareText = '${post.content.substring(0, 97)}...';
      } else {
        shareText = post.content;
      }
    }
    
    // 이미지가 있는 경우 텍스트 업데이트
    if (post.imageUrls.isNotEmpty) {
      if (shareText.isNotEmpty) {
        shareText += '\n\n';
      }
      shareText += '📷 Check out this moment from our journey together!';
    }
    
    // 앱 정보 추가
    shareText += '\n\n✨ Shared from Cosmic Couples App ✨';
    
    // 공유 대화상자 표시
    Share.share(shareText).then((_) {
      // 공유 완료 후 토스트 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Memory shared successfully!'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }
  }
}
