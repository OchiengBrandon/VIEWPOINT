import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String id;
  final String title;
  final String description;
  final String url;
  final String userId;
  final String userDocId; // Document ID of the user
  String userProfilePictureUrl; // Profile picture URL
  final String thumbnailUrl; // Thumbnail URL
  final Timestamp uploadDate;
  final Map<String, bool> likes; // User ID -> true for like
  final Map<String, bool> dislikes; // User ID -> true for dislike
  int views; // Number of views on the video
  int likesCount; // Number of likes
  int dislikesCount; // Number of dislikes
  int commentsCount; // Number of comments
  List<String> tags; // List of tags for the video
  String category; // Category of the video

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.userId,
    required this.userDocId, // Initialize userDocId
    this.userProfilePictureUrl = '',
    required this.thumbnailUrl,
    required this.uploadDate,
    Map<String, bool>? likes,
    Map<String, bool>? dislikes,
    this.views = 0,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.commentsCount = 0,
    required this.tags,
    required this.category,
  })  : likes = likes ?? {},
        dislikes = dislikes ?? {};

  // Method to create a Video instance from a map
  factory Video.fromMap(
      Map<String, dynamic> data, String id, String userDocId) {
    return Video(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      userId: data['userId'] ?? '',
      userDocId: userDocId, // Set the userDocId
      userProfilePictureUrl: data['userProfilePictureUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      uploadDate: data['uploadDate'] ?? Timestamp.now(),
      likes: Map<String, bool>.from(data['likes'] ?? {}),
      dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
      views: data['views'] ?? 0,
      likesCount: data['likesCount'] ?? 0,
      dislikesCount: data['dislikesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'] ?? '',
    );
  }

  // Method to listen for profile picture changes
  void _listenForProfilePictureChanges(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String newProfilePictureUrl = data['profilePictureUrl'] ?? '';
        // Update the profile picture URL if it has changed
        if (userProfilePictureUrl != newProfilePictureUrl) {
          userProfilePictureUrl = newProfilePictureUrl;
          _updateVideosProfilePicture(userId, newProfilePictureUrl);
        }
      }
    });
  }

  // Update the profile picture URL in all videos by the user
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

  /// Fetch the user's profile picture from Firestore
  Future<void> fetchUserProfilePicture() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        userProfilePictureUrl = data['profilePictureUrl'] ?? '';
      }
    } catch (e) {
      print("Error fetching user profile picture: $e");
    }
  }

  // Convert the Video instance to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'userId': userId,
      'userDocId': userDocId, // Include userDocId in the map
      'userProfilePictureUrl': userProfilePictureUrl,
      'thumbnailUrl': thumbnailUrl,
      'uploadDate': uploadDate,
      'likes': likes,
      'dislikes': dislikes,
      'views': views,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
      'commentsCount': commentsCount,
      'tags': tags,
      'category': category,
    };
  }

  // Method to save the video to Firestore
  Future<void> save() async {
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(id);
    await videoRef.set(toMap());
  }

  // Method to increment views
  Future<void> incrementViews() async {
    views++;
    await updateViews();
  }

  // Update views in Firestore
  Future<void> updateViews() async {
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(id);
    await videoRef.update({'views': views});
  }

  // Method to like the video
  Future<void> like(String userId) async {
    if (!likes.containsKey(userId)) {
      likes[userId] = true;
      dislikes.remove(userId); // Remove if previously disliked
      likesCount++;
      await updateLikesDislikes();
    }
  }

  // Method to dislike the video
  Future<void> dislike(String userId) async {
    if (!dislikes.containsKey(userId)) {
      dislikes[userId] = true;
      likes.remove(userId); // Remove if previously liked
      dislikesCount++;
      await updateLikesDislikes();
    }
  }

  // Update likes and dislikes in Firestore
  Future<void> updateLikesDislikes() async {
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(id);
    await videoRef.update({
      'likes': likes,
      'dislikes': dislikes,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
    });
  }

  // Increment comments count
  Future<void> incrementComments() async {
    commentsCount++;
    await updateCommentsCount();
  }

  // Update comments count in Firestore
  Future<void> updateCommentsCount() async {
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(id);
    await videoRef.update({'commentsCount': commentsCount});
  }

  // Static method to return an empty video instance
  static Video empty() {
    return Video(
      id: '',
      title: '',
      description: '',
      url: '',
      userId: '',
      userDocId: '', // Initialize userDocId
      thumbnailUrl: '',
      uploadDate: Timestamp.now(),
      likes: {},
      dislikes: {},
      views: 0,
      likesCount: 0,
      dislikesCount: 0,
      commentsCount: 0,
      userProfilePictureUrl: '',
      tags: [],
      category: '',
    );
  }
}
