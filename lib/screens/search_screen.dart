import 'package:flutter/material.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/services/video_service.dart';
import 'package:short_video_app/screens/video_player_screen.dart';
import 'package:short_video_app/utils/constants/categories.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final VideoService _videoService = VideoService();
  List<Video> _videos = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortOption = 'Relevance';

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    _videos = await _videoService.fetchVideos();
    _applyFiltersAndSorting();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _searchVideos() async {
    if (_searchQuery.isNotEmpty) {
      _videos = await _videoService.searchVideos(_searchQuery);
    } else {
      await _fetchVideos();
    }
    _applyFiltersAndSorting();
    if (mounted) {
      setState(() {});
    }
  }

  void _applyFiltersAndSorting() {
    if (_selectedCategory != null && _selectedCategory != 'All') {
      _videos = _videos
          .where((video) => video.category == _selectedCategory)
          .toList();
    }

    switch (_sortOption) {
      case 'Views':
        _videos.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'Likes':
        _videos.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
      case 'Relevance':
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Videos'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(child: _buildVideoGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
        _searchVideos();
      },
      decoration: InputDecoration(
        hintText: 'Search by title...',
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _videos = [];
            });
            _fetchVideos();
          },
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          hint: const Text('Select Category',
              style: TextStyle(color: Colors.white)),
          dropdownColor: Colors.grey[850],
          value: _selectedCategory,
          items: [
            {'title': 'All', 'icon': Icons.all_inbox},
            ...myCategories,
          ]
              .map<DropdownMenuItem<String>>(
                (category) => DropdownMenuItem<String>(
                  value: category['title'],
                  child: Row(
                    children: [
                      Icon(category['icon'], color: Colors.white),
                      const SizedBox(width: 10),
                      Text(category['title'],
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _searchVideos();
            });
          },
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
        ),
        DropdownButton<String>(
          value: _sortOption,
          dropdownColor: Colors.grey[850],
          items: ['Relevance', 'Views', 'Likes']
              .map<DropdownMenuItem<String>>(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child:
                      Text(option, style: const TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _sortOption = value!;
              _applyFiltersAndSorting();
            });
          },
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildVideoGrid() {
    if (_videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        return _buildVideoCard(context, _videos[index]);
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.grey[850],
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // User Details Section using StreamBuilder
            StreamBuilder<Map<String, String>>(
              stream: _videoService.streamUserDetailsByVideoId(video.id),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(); // Placeholder while loading
                } else if (userSnapshot.hasError) {
                  return const SizedBox(); // Handle error silently
                }

                final user = userSnapshot.data;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          user?['profilePictureUrl'] ?? '',
                        ),
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user?['name'] ?? 'Unknown User',
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${video.views} views",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "${video.likesCount} likes",
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
