import 'package:flutter/material.dart';
import 'package:short_video_app/widgets/video_player_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:short_video_app/models/video.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCommentAdded(String videoId, String commentText) {
    // Logic to add a comment (could call a service to save the comment)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? VideoPlayerWidget(
                controller: _controller,
                video: widget.video,
                onCommentAdded: _onCommentAdded,
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
