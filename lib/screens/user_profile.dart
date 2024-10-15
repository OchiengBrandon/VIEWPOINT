import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/screens/video_player_screen.dart';
import 'package:short_video_app/services/auth_service.dart';

class UserProfile extends StatefulWidget {
  final String userId;

  const UserProfile({super.key, required this.userId});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _isFollowing = false;
  bool _isLoading = true;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserData();
    _checkFollowStatus();
  }

  Future<void> _fetchUserData() async {
    try {
      _userData = await _authService.getUserById(widget.userId);
      _followersCount = await _authService.getFollowersCount(widget.userId);
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      List<dynamic> following = userDoc['following'] ?? [];
      setState(() {
        _isFollowing = following.contains(widget.userId);
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await _authService.unfollowUser(widget.userId);
      } else {
        await _authService.followUser(widget.userId);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      print("Error toggling follow status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData?['username'] ?? 'User Profile'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          _buildFollowButton(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserVideos(), // Videos tab
                _buildUserFollowers(), // Followers tab
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _showProfilePicture(context, _userData?['profilePictureUrl']);
            },
            child: CircleAvatar(
              backgroundImage:
                  NetworkImage(_userData?['profilePictureUrl'] ?? ''),
              radius: 40,
              child: _userData?['profilePictureUrl'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userData?['username'] ?? 'Loading...',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "$_followersCount Followers",
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                "${_userData?['following']?.length ?? 0} Following",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfilePicture(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return; // Do nothing if there's no image URL

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: SizedBox(
            width: double.infinity,
            height: 400, // Adjust the height as needed
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowButton() {
    final currentUserId = _authService.getCurrentUserId();

    // Check if the current user is viewing their own profile
    if (currentUserId == widget.userId) {
      return Container(); // Return an empty container if it's the current user's profile
    }

    return ElevatedButton(
      onPressed: _toggleFollow,
      child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Videos'),
          Tab(text: 'Followers'), // Followers tab
        ],
        indicatorColor: Colors.blue,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelColor: Colors.grey,
      ),
    );
  }

  Widget _buildUserVideos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final videos = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final videoData = videos[index].data() as Map<String, dynamic>;
            final video = Video(
              id: videos[index].id,
              title: videoData['title'] ?? '',
              description: videoData['description'] ?? '',
              url: videoData['url'] ?? '',
              userId: videoData['userId'] ?? '',
              userProfilePictureUrl: videoData['userProfilePictureUrl'] ?? '',
              thumbnailUrl: videoData['thumbnailUrl'] ?? '',
              uploadDate: videoData['uploadDate'] as Timestamp,
              likes: Map<String, bool>.from(videoData['likes'] ?? {}),
              dislikes: Map<String, bool>.from(videoData['dislikes'] ?? {}),
              views: videoData['views'] ?? 0,
              likesCount: videoData['likesCount'] ?? 0,
              dislikesCount: videoData['dislikesCount'] ?? 0,
              commentsCount: videoData['commentsCount'] ?? 0,
              tags: List<String>.from(videoData['tags'] ?? []),
              category: videoData['category'] ?? '',
              userDocId: videoData['userDocId'] ?? '',
            );

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: video),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Stack(
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      height: 100, // Height of the thumbnail
                      width: double.infinity, // Ensure full width
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        color: Colors.black54, // Semi-transparent background
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow,
                                color: Colors.white, size: 16),
                            const SizedBox(
                                width: 4), // Space between icon and text
                            Text(
                              '${video.views} Views',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserFollowers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final followers = snapshot.data!.docs;

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final followerData =
                followers[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(followerData['profilePictureUrl'] ?? ''),
              ),
              title: Text(followerData['username'] ?? 'Loading...'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(followerData['userId'] ?? '',
                      style: const TextStyle(color: Colors.grey)),
                  Text(
                      "${followerData['followingCount'] ?? 0} Following • ${followerData['followersCount'] ?? 0} Followers",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              onTap: () {
                // Navigate to follower's profile if needed
              },
            );
          },
        );
      },
    );
  }
}
