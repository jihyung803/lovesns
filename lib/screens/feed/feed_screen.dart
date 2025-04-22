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

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
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
      return const LoadingIndicator();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreatePostScreen,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // Stories section
            SliverToBoxAdapter(
              child: _buildStoriesSection(storyService),
            ),
            
            // Posts section
            postService.posts.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No posts yet. Create your first post!',
                          style: AppTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = postService.posts[index];
                        return PostCard(
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
                        );
                      },
                      childCount: postService.posts.length,
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStoriesSection(StoryService storyService) {
    final todayMission = storyService.todayMission;
    final stories = storyService.stories;
    
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Today\'s Mission',
              style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: stories.isEmpty ? 1 : stories.length + 1,
              itemBuilder: (context, index) {
                // First item is always the create story bubble
                if (index == 0) {
                  return StoryBubble(
                    isCreateBubble: true,
                    missionTitle: todayMission?.title ?? 'Daily Mission',
                    missionDescription: todayMission?.description ?? 'Complete today\'s mission',
                    onTap: _showCreateStoryScreen,
                  );
                }
                
                // Other items are existing stories
                final story = stories[index - 1];
                return StoryBubble(
                  imageUrl: story.imageUrl,
                  isViewed: story.isViewed,
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
    );
  }
}