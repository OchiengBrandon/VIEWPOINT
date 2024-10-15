import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/models/comment.dart';
import 'package:short_video_app/services/video_service.dart';
import 'package:short_video_app/services/auth_service.dart';
import 'package:short_video_app/widgets/video_player_widget.dart';
import 'package:video_player/video_player.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  _VideoFeedScreenState createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final VideoService _videoService = VideoService();
  final AuthService _authService = AuthService();
  List<Video> _videos = [];
  List<VideoPlayerController> _videoControllers = [];
  int _currentIndex = 0;
  String? _errorMessage;
  List<Video>? _cachedVideos;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isRefreshing = true;
    });

    if (_cachedVideos != null) {
      setState(() {
        _videos = _cachedVideos!;
        _initializeVideoControllers();
      });
      _isRefreshing = false;
      return;
    }

    try {
      final videos = await _videoService.fetchVideos();
      setState(() {
        _videos = videos;
        _cachedVideos = videos;
        _initializeVideoControllers();
        if (_currentIndex < _videoControllers.length) {
          _videoControllers[_currentIndex].play(); // Play the current video
        }
      });
    } catch (e) {
      print("Error loading videos: $e");
      setState(() {
        _errorMessage = "Failed to load videos. Please try again later.";
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _initializeVideoControllers() {
    for (var controller in _videoControllers) {
      controller.dispose();
    }

    _videoControllers = _videos
        .map((video) => VideoPlayerController.network(video.url))
        .toList();

    for (var controller in _videoControllers) {
      controller.initialize().then((_) {
        if (_currentIndex == _videoControllers.indexOf(controller)) {
          controller.play();
        }
      });
    }
  }

  Future<void> _addComment(String videoId, String commentText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || commentText.isEmpty) return;

    final userDetails = await _authService.getUserDetails();
    final username = userDetails['username'];
    final profilePictureUrl = userDetails['profilePictureUrl'] ?? '';

    if (username == null) return;

    final commentId = FirebaseFirestore.instance
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc()
        .id;

    final comment = Comment(
      id: commentId,
      videoId: videoId,
      userId: user.uid,
      username: username,
      profilePictureUrl: profilePictureUrl,
      content: commentText,
      timestamp: Timestamp.now(),
      likes: {},
      dislikes: {},
    );

    await _videoService.addComment(videoId, comment);
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_videos.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadVideos,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _videos.length,
              controller: PageController(
                  viewportFraction: 1, initialPage: _currentIndex),
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                if (_currentIndex != index) {
                  setState(() {
                    _videoControllers[_currentIndex].pause();
                    _currentIndex = index;
                    _videoControllers[_currentIndex].play();
                  });
                }
              },
              itemBuilder: (context, index) {
                return VideoPlayerWidget(
                  controller: _videoControllers[index],
                  video: _videos[index],
                  onCommentAdded: _addComment,
                );
              },
            ),
            if (_isRefreshing)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "Refreshing videos...",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensures the widget keeps its state
}
