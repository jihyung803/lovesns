import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/models/post.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/post_service.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({Key? key}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  Post? _post;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  bool _isSubmittingComment = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostDetails();
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final postId = ModalRoute.of(context)!.settings.arguments as String;
      final postService = Provider.of<PostService>(context, listen: false);
      final post = await postService.getPostById(postId);
      
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _likePost() async {
    if (_post == null) return;
    
    try {
      final postService = Provider.of<PostService>(context, listen: false);
      await postService.likePost(_post!.id);
      
      // Refresh post details
      _loadPostDetails();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }
  
  Future<void> _addComment() async {
    if (_post == null || _commentController.text.trim().isEmpty) return;
    
    setState(() {
      _isSubmittingComment = true;
    });
    
    try {
      final postService = Provider.of<PostService>(context, listen: false);
      await postService.addComment(_post!.id, _commentController.text.trim());
      
      // Clear comment field
      _commentController.clear();
      
      // Refresh post details
      await _loadPostDetails();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }
  
  Future<void> _deleteComment(String commentId) async {
    if (_post == null) return;
    
    try {
      final postService = Provider.of<PostService>(context, listen: false);
      await postService.deleteComment(_post!.id, commentId);
      
      // Refresh post details
      _loadPostDetails();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }
  
  Future<void> _deletePost() async {
    if (_post == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final postService = Provider.of<PostService>(context, listen: false);
      final bool success = await postService.deletePost(_post!.id);
      
      if (success && mounted) {
        Navigator.pop(context);
      } else {
        setState(() {
          _error = 'Failed to delete post';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _confirmDeletePost() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.pop(context);
                _deletePost();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }
  
  void _confirmDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.pop(context);
                _deleteComment(commentId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: ErrorDialog(
          message: _error!,
          onRetry: _loadPostDetails,
        ),
      );
    }
    
    if (_post == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: Text('Post not found')),
      );
    }
    final bool isUserPost = _post!.userId == user.id;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (isUserPost)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeletePost,
            ),
        ],
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Post header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            isUserPost ? user.username[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundImage: isUserPost && user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!) as ImageProvider
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUserPost ? 'You' : 'Partner',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                timeago.format(_post!.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Post content
                  if (_post!.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _post!.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  
                  // Post images
                  if (_post!.imageUrls.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        CarouselSlider(
                          options: CarouselOptions(
                            aspectRatio: 1,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                          items: _post!.imageUrls.map((imageUrl) {
                            return Builder(
                              builder: (context) {
                                return Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            );
                          }).toList(),
                        ),
                        
                        // Image indicators
                        if (_post!.imageUrls.length > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _post!.imageUrls.asMap().entries.map((entry) {
                                return Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  
                  // Like count
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _post!.isLikedByPartner
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _post!.isLikedByPartner
                                ? Colors.red
                                : Colors.grey.shade600,
                          ),
                          onPressed: _likePost,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_post!.likeCount} likes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Comments
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Comments (${_post!.comments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Comments list
                  if (_post!.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _post!.comments.length,
                      itemBuilder: (context, index) {
                        final comment = _post!.comments[index];
                        final bool isUserComment = comment.userId == user.id;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isUserComment
                                    ? AppTheme.primaryColor
                                    : AppTheme.secondaryColor,
                                child: Text(
                                  comment.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundImage: comment.userImageUrl != null
                                    ? NetworkImage(comment.userImageUrl!) as ImageProvider
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isUserComment ? 'You' : comment.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeago.format(comment.createdAt),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUserComment)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => _confirmDeleteComment(comment.id),
                                  color: Colors.grey.shade600,
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
          
          // Add comment section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!) as ImageProvider
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                    enabled: !_isSubmittingComment,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isSubmittingComment
                        ? Colors.grey.shade400
                        : AppTheme.primaryColor,
                  ),
                  onPressed: _isSubmittingComment ? null : _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}