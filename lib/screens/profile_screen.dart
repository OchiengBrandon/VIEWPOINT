import 'package:firebase_storage/firebase_storage.dart'; // Ensure this import is included
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:short_video_app/screens/user_profile.dart';
import 'package:short_video_app/screens/video_player_screen.dart';
import 'dart:io';
import 'package:short_video_app/services/auth_service.dart';
import 'package:short_video_app/services/video_service.dart';
import 'package:short_video_app/models/video.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _email;
  String? _phone;
  XFile? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false; // Added loading state
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final VideoService _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String?>> _loadUserDetails() async {
    return await _authService.getUserDetails();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  Future<void> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');
      await storageRef.putFile(File(_profileImage!.path));
      final downloadUrl = await storageRef.getDownloadURL();
      await _authService.updateUserDetails(_username!, _phone!, downloadUrl);
      await _updateVideosProfilePicture(userId, downloadUrl);
      await _updateVideosUsername(userId); // Update username in videos

      setState(() {
        _profileImage = XFile(downloadUrl);
      });
    } catch (e) {
      print("Failed to upload image: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image.')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _updateVideosProfilePicture(
      String userId, String profilePictureUrl) async {
    final videosSnapshot = await FirebaseFirestore.instance
        .collection('videos')
        .where('userId', isEqualTo: userId)
        .get();

    for (var videoDoc in videosSnapshot.docs) {
      final videoRef =
          FirebaseFirestore.instance.collection('videos').doc(videoDoc.id);
      await videoRef.update({'userProfilePictureUrl': profilePictureUrl});
    }
  }

  Future<void> _updateVideosUsername(String userId) async {
    final videosSnapshot = await FirebaseFirestore.instance
        .collection('videos')
        .where('userId', isEqualTo: userId)
        .get();

    for (var videoDoc in videosSnapshot.docs) {
      final videoRef =
          FirebaseFirestore.instance.collection('videos').doc(videoDoc.id);
      await videoRef.update({'userId': _username}); // Update username
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userDetails = await _authService.getUserDetails();
      final userId = userDetails['uid'];

      if (userId != null) {
        await _authService.updateUserDetails(_username!, _phone!, null);
        await _uploadProfileImage(userId);

        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      } else {
        print("User ID is null.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: _loadUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading user data"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No user data found"));
          }

          _username ??= snapshot.data!['username'];
          _email ??= snapshot.data!['email'];
          _phone ??= snapshot.data!['phone'];

          String? existingProfilePictureUrl =
              snapshot.data!['profilePictureUrl'];
          if (existingProfilePictureUrl != null && _profileImage == null) {
            _profileImage = XFile(existingProfilePictureUrl);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? _profileImage!.path.startsWith('http')
                                ? NetworkImage(_profileImage!.path)
                                : FileImage(File(_profileImage!.path))
                            : null,
                        backgroundColor: Colors.blue,
                        child: _profileImage == null
                            ? Text(
                                _username?.substring(0, 1) ?? 'U',
                                style: const TextStyle(
                                    fontSize: 30, color: Colors.white),
                              )
                            : null,
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _username ?? 'User',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _email ?? 'example@example.com',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Edit Profile",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.check : Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text("Profile Details",
                      style: TextStyle(fontSize: 18)),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Username',
                            initialValue: _username,
                            onSaved: (value) => _username = value,
                            isEditing: _isEditing,
                          ),
                          _buildTextField(
                            label: 'Email',
                            initialValue: _email,
                            readOnly: true,
                          ),
                          _buildTextField(
                            label: 'Phone',
                            initialValue: _phone,
                            onSaved: (value) => _phone = value,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          if (_isEditing)
                            ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text('Save Changes'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.blue,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: "Liked Videos"),
                          Tab(text: "Posted Videos"),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            LikedVideosTab(userId: snapshot.data!['uid']),
                            PostedVideosTab(userId: snapshot.data!['uid']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    Function(String?)? onSaved,
    bool isEditing = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        initialValue: initialValue,
        onSaved: onSaved,
        enabled: isEditing,
        readOnly: readOnly,
        validator: (value) {
          if (isEditing && (value == null || value.isEmpty)) {
            return 'Please enter a $label';
          }
          return null;
        },
      ),
    );
  }
}

class LikedVideosTab extends StatelessWidget {
  final String? userId;
  final VideoService _videoService = VideoService();

  LikedVideosTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Video>>(
      future: _videoService.fetchLikedVideos(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading liked videos"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No liked videos found"));
        }

        final likedVideos = snapshot.data!;
        return ListView.builder(
          itemCount: likedVideos.length,
          itemBuilder: (context, index) {
            return _buildVideoCard(context, likedVideos[index]);
          },
        );
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return StreamBuilder<Map<String, String>>(
      stream: _videoService
          .streamUserDetailsByVideoId(video.id), // Assuming video.id exists
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120, // Increased height for loading
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const SizedBox(
            height: 120, // Placeholder height
            child: Center(child: Text("Error loading user details")),
          );
        }

        final userData = snapshot.data ??
            {'name': '', 'profilePictureUrl': '', 'userId': ''};

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4, // Slightly increased elevation for depth
          child: InkWell(
            onTap: () {
              // Navigate to video detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(video: video),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Increased padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail and Video Details
                  Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          video.thumbnailUrl,
                          width: 120, // Increased thumbnail width
                          height: 90, // Increased thumbnail height
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.black,
                              child: const Center(
                                child: Text(
                                  'Thumbnail not available',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Video details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Video Title
                            Text(
                              video.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Increased font size for title
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4.0),
                            // Video Description
                            Text(
                              video.description,
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14), // Increased font size
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4.0),
                            // Likes Count
                            Text(
                              "Likes: ${video.likesCount}",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14), // Increased font size
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height:
                          8.0), // Space between video details and profile section
                  // Profile Image and Username
                  InkWell(
                    onTap: () {
                      // Navigate to UserProfile when CircleAvatar is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfile(
                              userId: userData['userId']!), // Pass userId
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage(userData['profilePictureUrl']!),
                          radius: 20, // Adjusted profile picture size
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            userData['name']!,
                            style: const TextStyle(
                              fontSize: 14, // Increased font size for username
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PostedVideosTab extends StatelessWidget {
  final String? userId;
  final VideoService _videoService = VideoService();

  PostedVideosTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Video>>(
      future: _videoService.fetchPostedVideos(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading posted videos"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No posted videos found"));
        }

        final postedVideos = snapshot.data!;
        return ListView.builder(
          itemCount: postedVideos.length,
          itemBuilder: (context, index) {
            return _buildVideoCard(context, postedVideos[index]);
          },
        );
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(video: video),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120, // Further reduced height
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'Thumbnail not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Video Title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                video.title,
                style: const TextStyle(
                  fontSize: 14, // Small title font size
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Video Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                video.description,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Statistics Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${video.likesCount} likes",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "${video.views} views",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "${video.commentsCount} comments",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
