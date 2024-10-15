import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:short_video_app/models/comment.dart';
import 'package:short_video_app/models/reply.dart';
import 'package:short_video_app/services/comment_service.dart';
import 'package:short_video_app/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllCommentsScreen extends StatefulWidget {
  final String videoId;

  const AllCommentsScreen({super.key, required this.videoId});

  @override
  _AllCommentsScreenState createState() => _AllCommentsScreenState();
}

class _AllCommentsScreenState extends State<AllCommentsScreen> {
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  late Future<List<Comment>> _commentsFuture;
  String? _currentUsername;
  String? _currentUserId;
  String? _currentProfilePictureUrl;
  Stream<DocumentSnapshot>? _userProfileStream;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _commentsFuture = _commentService.fetchComments(widget.videoId);
  }

  Future<void> _fetchCurrentUser() async {
    final userDetails = await _authService.getUserDetails();
    setState(() {
      _currentUsername = userDetails['username'];
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      _currentProfilePictureUrl = userDetails['profilePictureUrl'];
    });

    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      _userProfileStream = _authService.listenForProfileChanges(userId);
      _userProfileStream?.listen((userSnapshot) {
        if (userSnapshot.exists) {
          setState(() {
            _currentProfilePictureUrl = userSnapshot['profilePictureUrl'];
          });
        }
      });
    }
  }

  void _submitComment() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    String commentContent = _commentController.text.trim();

    if (userId != null && commentContent.isNotEmpty) {
      final comment = Comment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        videoId: widget.videoId,
        userId: userId,
        username: _currentUsername!,
        profilePictureUrl: _currentProfilePictureUrl ?? 'URL_TO_DEFAULT_IMAGE',
        content: commentContent,
        timestamp: Timestamp.now(),
        likes: {},
        dislikes: {},
      );

      await _commentService.addComment(widget.videoId, comment);
      _commentController.clear();
      _showSnackBar("Comment added!");
      setState(() {
        _commentsFuture = _commentService.fetchComments(widget.videoId);
      });
    } else {
      _showSnackBar("Please enter a comment.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No comments yet.",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentCard(
                      comment: comment,
                      currentUsername: _currentUsername,
                      currentUserId: _currentUserId,
                      videoId: widget.videoId,
                      commentService: _commentService,
                      currentProfilePictureUrl: _currentProfilePictureUrl,
                    );
                  },
                );
              },
            ),
          ),
          _buildAddCommentSection(),
        ],
      ),
    );
  }

  Widget _buildAddCommentSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                fillColor: Colors.grey,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class CommentCard extends StatefulWidget {
  final Comment comment;
  final String? currentUsername;
  final String? currentUserId;
  final String videoId;
  final CommentService commentService;
  final String? currentProfilePictureUrl;

  const CommentCard({
    super.key,
    required this.comment,
    required this.currentUsername,
    required this.currentUserId,
    required this.videoId,
    required this.commentService,
    required this.currentProfilePictureUrl,
  });

  @override
  _CommentCardState createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard>
    with SingleTickerProviderStateMixin {
  bool _showReplies = false;
  final TextEditingController _replyController = TextEditingController();
  bool _liked = false;
  bool _disliked = false;
  late AnimationController _likeAnimationController;
  Animation<double>? _likeAnimation; // Make it nullable

  @override
  void initState() {
    super.initState();
    _liked = widget.comment.likes.containsKey(widget.currentUserId);
    _disliked = widget.comment.dislikes.containsKey(widget.currentUserId);

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.comment.profilePictureUrl.isNotEmpty
                      ? widget.comment.profilePictureUrl
                      : 'URL_TO_DEFAULT_IMAGE',
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 20,
                  ),
                  placeholder: (context, url) => const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 20,
                    child: Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Posted by: ${widget.comment.userId == widget.currentUserId ? 'You' : widget.comment.username}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.comment.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildCommentActions(),
            if (_showReplies) _buildRepliesSection(),
            if (_showReplies) _buildReplyInput(),
            TextButton(
              onPressed: _toggleReplies,
              child: Text(
                _showReplies ? 'Hide replies' : 'View replies',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildCommentActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(
          icon: _liked ? Icons.thumb_up : Icons.thumb_up_off_alt,
          onPressed: () => _toggleLike(widget.comment.id),
          likeCount: widget.comment.likes.length,
        ),
        _buildActionIcon(
          icon: _disliked ? Icons.thumb_down : Icons.thumb_down_off_alt,
          onPressed: () => _toggleDislike(widget.comment.id),
          likeCount: widget.comment.dislikes.length,
        ),
        _buildActionIcon(
          icon: Icons.reply,
          onPressed: _toggleReplies,
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onPressed,
    int? likeCount,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            onPressed();
            if (icon == Icons.thumb_up) {
              _likeAnimationController
                  .forward()
                  .then((_) => _likeAnimationController.reverse());
            }
          },
          child: ScaleTransition(
            scale: _likeAnimation ??
                const AlwaysStoppedAnimation(1.0), // Use default if null
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
        if (likeCount != null) ...[
          const SizedBox(width: 4),
          Text(
            likeCount.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleLike(String commentId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      if (_liked) {
        _liked = false;
        widget.comment.likes.remove(userId);
      } else {
        _liked = true;
        widget.comment.likes[userId] = true;
        _disliked = false;
        widget.comment.dislikes.remove(userId);
      }
    });

    await widget.commentService
        .toggleLikeDislike(widget.videoId, commentId, userId, true);
  }

  Future<void> _toggleDislike(String commentId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      if (_disliked) {
        _disliked = false;
        widget.comment.dislikes.remove(userId);
      } else {
        _disliked = true;
        widget.comment.dislikes[userId] = true;
        _liked = false;
        widget.comment.likes.remove(userId);
      }
    });

    await widget.commentService
        .toggleLikeDislike(widget.videoId, commentId, userId, false);
  }

  FutureBuilder<List<Reply>> _buildRepliesSection() {
    return FutureBuilder<List<Reply>>(
      future:
          widget.commentService.fetchReplies(widget.videoId, widget.comment.id),
      builder: (context, replySnapshot) {
        if (replySnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          );
        }
        if (replySnapshot.hasError) {
          return Text("Error: ${replySnapshot.error}",
              style: const TextStyle(color: Colors.red));
        }
        if (!replySnapshot.hasData || replySnapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No replies yet.",
                style: TextStyle(color: Colors.white70)),
          );
        }

        final replies = replySnapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: replies.length,
          itemBuilder: (context, replyIndex) {
            final reply = replies[replyIndex];
            return _buildReplyCard(reply);
          },
        );
      },
    );
  }

  Widget _buildReplyCard(Reply reply) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.userId == widget.currentUserId ? 'You' : reply.username,
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            reply.content,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                hintText: "Type your reply...",
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                filled: true,
                fillColor: Colors.grey,
              ),
              maxLines: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _submitReply,
          ),
        ],
      ),
    );
  }

  void _submitReply() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final username = widget.currentUsername;
    String replyContent = _replyController.text.trim();

    if (userId != null && replyContent.isNotEmpty && username != null) {
      final reply = Reply(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        commentId: widget.comment.id,
        userId: userId,
        username: username,
        content: replyContent,
        timestamp: Timestamp.now(),
        likes: {},
        dislikes: {},
      );

      await widget.commentService
          .addReply(widget.videoId, widget.comment.id, reply);
      _replyController.clear();
      _showSnackBar("Reply added!");
      setState(() {}); // Refresh replies
    } else {
      _showSnackBar("Please enter a reply.");
    }
  }

  void _toggleReplies() {
    setState(() {
      _showReplies = !_showReplies;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
