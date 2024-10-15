import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:short_video_app/screens/all_comment_screen.dart';
import 'package:short_video_app/screens/user_profile.dart';
import 'package:video_player/video_player.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/services/video_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final Video video;
  final Function(String videoId, String commentText) onCommentAdded;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.video,
    required this.onCommentAdded,
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final VideoService _videoService = VideoService();
  late String _username;
  late String _profilePictureUrl;
  late AnimationController _animationController;
  bool _showLikeBubble = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _username = '';
    _profilePictureUrl = ''; // Initialize profile picture URL
    _fetchUserDetails(widget.video.id); // Change here to use video.id
    _checkFollowStatus(widget.video.userId);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    widget.controller.addListener(_videoPlayerListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoPlayerListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _videoPlayerListener() {
    if (widget.controller.value.position == widget.controller.value.duration) {
      widget.controller.seekTo(Duration.zero);
      widget.controller.play();
    }
  }

  void _fetchUserDetails(String videoDocId) {
    // Listen to the stream of user details based on the video document ID
    _videoService.streamUserDetailsByVideoId(videoDocId).listen(
        (userProfileData) {
      if (mounted) {
        setState(() {
          _username =
              userProfileData['name'] ?? 'Unknown User'; // Set actual username
          _profilePictureUrl = userProfileData['profilePictureUrl'] ??
              ''; // Set profile picture URL
        });
      }
    }, onError: (e) {
      debugPrint("Error fetching user details: $e");
    });
  }

  Future<void> _checkFollowStatus(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(userId)
          .get();
      if (mounted) {
        setState(() {
          _isFollowing = doc.exists;
        });
      }
    } catch (e) {
      debugPrint("Error checking follow status: $e");
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (_isFollowing) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(widget.video.userId)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(widget.video.userId)
            .set({});
      }
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      debugPrint("Error toggling follow status: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      setState(() {
        if (widget.video.likes.containsKey(userId)) {
          widget.video.likes.remove(userId);
          _showLikeBubble = false;
          _animationController.reverse();
        } else {
          widget.video.likes[userId] = true;
          _showLikeBubble = true;
          _animationController.forward();
        }
      });

      if (_showLikeBubble) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _showLikeBubble = false;
          });
        }
      }
      await _videoService.toggleVideoLikeDislike(widget.video.id, userId, true);
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      await _videoService.incrementViews(widget.video.id);
      if (mounted) {
        setState(() {
          widget.video.views += 1;
        });
      }
    } catch (e) {
      debugPrint("Error incrementing view count: $e");
    }
  }

  void _onSingleTap() async {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      await _incrementViewCount();
      widget.controller.play();
    }
  }

  void _onDoubleTap() {
    _toggleFavorite();
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black54,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: AllCommentsScreen(videoId: widget.video.id),
        ),
      ),
    );
  }

  void _showVideoDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailHeader(),
              const SizedBox(height: 8),
              _buildProfileAndFollow(),
              const SizedBox(height: 8),
              _buildDetailInfo(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            "Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildProfileAndFollow() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfile(userId: widget.video.userId),
              ),
            );
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(_profilePictureUrl),
            radius: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _username.isNotEmpty ? _username : "Loading...",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (currentUserId != widget.video.userId)
                TextButton(
                  onPressed: _toggleFollow,
                  child: Text(
                    _isFollowing ? "Unfollow" : "Follow",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Posted by: $_username",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "${widget.video.views} views",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "${widget.video.likes.length} likes",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "${widget.video.commentsCount} comments",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "Category: ${widget.video.category}",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "Tags: ${widget.video.tags.join(', ')}",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: _onSingleTap,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: VideoPlayer(widget.controller),
              ),
            ),
          ),
          _buildControlPanel(),
          _buildBottomInfo(),
          if (_showLikeBubble) _buildLikeBubble(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      right: 16,
      top: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildFavoriteButton(),
          _buildLikesCount(),
          const SizedBox(height: 20),
          _buildCommentButton(),
          _buildCommentsCount(),
          const SizedBox(height: 20),
          _buildShareButton(),
          const SizedBox(height: 20),
          _buildVideoDetailButton(),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    return Text(
      "${widget.video.likes.length}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCommentsCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.video.id)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text(
            "0 comments",
            style: TextStyle(color: Colors.white, fontSize: 12),
          );
        }
        final comments = snapshot.data!.docs;
        return Text(
          "${comments.length} ",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(),
            const SizedBox(height: 8),
            _buildVideoInfo(),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showCommentsBottomSheet,
              child: _buildViewCommentsLink(),
            ),
            const SizedBox(height: 4),
            _buildViewCount(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showVideoDetails,
          child: CircleAvatar(
            backgroundImage: NetworkImage(_profilePictureUrl),
            radius: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _username.isNotEmpty ? _username : "Loading...",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.video.title.isNotEmpty
              ? widget.video.title
              : "Title not available",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.video.description.isNotEmpty
              ? widget.video.description
              : "No description available",
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.video.category.isNotEmpty
                    ? widget.video.category
                    : "No category",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.video.tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewCommentsLink() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.video.id)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final comments = snapshot.data!.docs;
        return GestureDetector(
          onTap: _showCommentsBottomSheet,
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "View all ${comments.length} comments",
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewCount() {
    return Text(
      "${widget.video.views} views",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: Icon(
        widget.video.likes.containsKey(FirebaseAuth.instance.currentUser?.uid)
            ? Icons.favorite
            : Icons.favorite_border,
        color: widget.video.likes
                .containsKey(FirebaseAuth.instance.currentUser?.uid)
            ? Colors.red
            : Colors.white,
      ),
      onPressed: _toggleFavorite,
      iconSize: 30,
    );
  }

  Widget _buildCommentButton() {
    return IconButton(
      icon: const Icon(Icons.comment, color: Colors.white),
      onPressed: _showCommentsBottomSheet,
      iconSize: 30,
    );
  }

  Widget _buildShareButton() {
    return IconButton(
      icon: const Icon(Icons.share, color: Colors.white),
      onPressed: () {
        // Implement share functionality
        debugPrint("Share button pressed");
      },
      iconSize: 30,
    );
  }

  Widget _buildVideoDetailButton() {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.white),
      onPressed: _showVideoDetails,
      iconSize: 30,
    );
  }

  Widget _buildLikeBubble() {
    return Positioned(
      top: 50,
      left: MediaQuery.of(context).size.width / 2 - 30,
      child: AnimatedOpacity(
        opacity: _showLikeBubble ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
