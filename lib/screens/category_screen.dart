import 'package:flutter/material.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/services/video_service.dart';
import 'package:short_video_app/screens/video_player_screen.dart';
import 'package:short_video_app/utils/constants/categories.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final VideoService _videoService = VideoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Category'),
        backgroundColor: Colors.black,
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        padding: const EdgeInsets.all(10.0),
        itemCount: myCategories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(myCategories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideosListScreen(category: category['title']),
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category['icon'],
                size: 50,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 10),
              Text(
                category['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideosListScreen extends StatelessWidget {
  final String category;
  final VideoService videoService = VideoService(); // Create an instance here

  VideosListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Videos'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Video>>(
        stream: videoService.streamVideosByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No videos available in this category.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final videos = snapshot.data!;
          return ListView(
            children: [
              _buildHeader(category),
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(10.0),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return _buildVideoCard(context, video);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String category) {
    return GestureDetector(
      onTap: () {
        // Optional: Do something when header is tapped
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.blueAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.expand_more, color: Colors.white),
          ],
        ),
      ),
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 500, // Set a maximum height for the card
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    video.thumbnailUrl,
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  video.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis, // Ensure title fits
                ),
              ),
              const Divider(color: Colors.grey), // Divider for separation
              SizedBox(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatColumn('Views', video.views),
                    _buildStatColumn('Likes', video.likesCount),
                    _buildStatColumn('Comments', video.commentsCount),
                  ],
                ),
              ),
              // Profile Section
              StreamBuilder<Map<String, String>>(
                stream: videoService.streamUserDetailsByVideoId(video.id),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(); // Placeholder while loading
                  } else if (userSnapshot.hasError) {
                    return const SizedBox(); // Handle error silently
                  }

                  final user = userSnapshot.data;
                  return SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (user != null && user['profilePictureUrl'] != null)
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage(user['profilePictureUrl']!),
                            radius: 20,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user?['name'] ?? 'Unknown User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}
