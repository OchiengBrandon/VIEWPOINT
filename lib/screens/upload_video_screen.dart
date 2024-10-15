import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:short_video_app/utils/constants/categories.dart';
import 'package:video_player/video_player.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/services/auth_service.dart';
import 'package:short_video_app/services/video_service.dart';
import 'dart:io';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final AuthService _authService = AuthService();
  final VideoService _videoService = VideoService();

  File? _videoFile;
  File? _thumbnailFile;
  VideoPlayerController? _videoPlayerController;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  String? _selectedCategory;
  final List<String> _categories =
      myCategories.map((category) => category['title'] as String).toList();

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _videoPlayerController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {});
          });
      });
    } else {
      _showSnackBar("No video selected.");
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    } else {
      _showSnackBar("No thumbnail selected.");
    }
  }

  Future<void> _uploadVideo() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final tags = _tagsController.text
        .trim()
        .split(',')
        .map((tag) => tag.trim())
        .toList();

    if (_videoFile == null ||
        _thumbnailFile == null ||
        title.isEmpty ||
        description.isEmpty ||
        _selectedCategory == null) {
      _showSnackBar(
          "Please fill in all fields and select a video and thumbnail.");
      return;
    }

    final userDetails = await _authService.getUserDetails();
    final userId = userDetails['uid'];
    final userProfilePictureUrl = userDetails['profilePictureUrl'];
    final userDocId = userId ??
        ''; // Use userId as userDocId, default to empty string if null

    if (userId == null || userProfilePictureUrl == null) {
      _showSnackBar("User not found. Please log in again.");
      return;
    }

    final storageRef = FirebaseStorage.instance.ref();
    final videoRef =
        storageRef.child('videos/${DateTime.now().microsecondsSinceEpoch}.mp4');
    final thumbnailRef = storageRef
        .child('thumbnails/${DateTime.now().microsecondsSinceEpoch}.jpg');

    try {
      setState(() {
        _isUploading = true;
      });

      final uploadVideoTask = videoRef.putFile(_videoFile!);
      final uploadThumbnailTask = thumbnailRef.putFile(_thumbnailFile!);

      uploadVideoTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred.toDouble() /
              snapshot.totalBytes.toDouble();
        });
      });

      await Future.wait([uploadVideoTask, uploadThumbnailTask]);

      final videoUrl = await videoRef.getDownloadURL();
      final thumbnailUrl = await thumbnailRef.getDownloadURL();

      final newVideo = Video(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: description,
        url: videoUrl,
        userId: userId,
        userProfilePictureUrl: userProfilePictureUrl,
        userDocId: userDocId, // Safely assigned
        thumbnailUrl: thumbnailUrl,
        uploadDate: Timestamp.now(),
        views: 0,
        tags: tags,
        category: _selectedCategory!,
      );

      await _videoService.addVideo(newVideo);
      _showSnackBar("Video uploaded successfully!");

      _titleController.clear();
      _descriptionController.clear();
      _tagsController.clear();
      setState(
        () {
          _videoFile = null;
          _thumbnailFile = null;
          _isUploading = false;
          _uploadProgress = 0.0;
          _videoPlayerController?.dispose();
          _videoPlayerController = null;
        },
      );
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Video upload failed: ${e.toString()}");
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Video"),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Upload Video",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(_titleController, "Video Title"),
              const SizedBox(height: 10),
              _buildTextField(_descriptionController, "Description",
                  maxLines: 3),
              const SizedBox(height: 10),
              _buildTextField(_tagsController, "Tags (comma separated)",
                  maxLines: 1),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Select Category",
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Select Video"),
              ),
              ElevatedButton(
                onPressed: _pickThumbnail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Select Thumbnail"),
              ),
              const SizedBox(height: 10),
              if (_videoFile != null) ...[
                Text(
                  "Selected Video: ${_videoFile!.path.split('/').last}",
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                if (_videoPlayerController != null &&
                    _videoPlayerController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _videoPlayerController!.value.isPlaying
                          ? _videoPlayerController!.pause()
                          : _videoPlayerController!.play();
                    });
                  },
                  child: Icon(
                    _videoPlayerController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (_isUploading) _buildUploadProgress(),
              if (!_isUploading) _buildUploadButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.pink),
        ),
        filled: true,
        fillColor: Colors.grey[850],
      ),
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildUploadProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
          const SizedBox(height: 10),
          Text(
            "Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: _uploadVideo,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text("Upload"),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
