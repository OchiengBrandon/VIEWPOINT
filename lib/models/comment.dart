import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String videoId;
  final String userId;
  final String username; // Field for username
  final String profilePictureUrl; // Field for profile picture URL
  final String content;
  final Timestamp timestamp;
  final Map<String, bool> likes; // User ID -> true for like
  final Map<String, bool> dislikes; // User ID -> true for dislike

  Comment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.username, // Include username in constructor
    required this.profilePictureUrl, // Include profile picture URL in constructor
    required this.content,
    required this.timestamp,
    Map<String, bool>? likes,
    Map<String, bool>? dislikes,
  })  : likes = likes ?? {},
        dislikes = dislikes ?? {};

  // Method to save the comment to Firestore
  Future<void> save() async {
    final commentRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(id);
    await commentRef.set({
      'userId': userId,
      'username': username, // Save username to Firestore
      'profilePictureUrl':
          profilePictureUrl, // Save profile picture URL to Firestore
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'dislikes': dislikes,
    });
  }

  // Method to like the comment
  Future<void> like(String userId) async {
    if (!likes.containsKey(userId)) {
      likes[userId] = true; // Add like
      dislikes.remove(userId); // Remove dislike if exists
      await updateLikesDislikes(); // Update Firestore
    }
  }

  // Method to dislike the comment
  Future<void> dislike(String userId) async {
    if (!dislikes.containsKey(userId)) {
      dislikes[userId] = true; // Add dislike
      likes.remove(userId); // Remove like if exists
      await updateLikesDislikes(); // Update Firestore
    }
  }

  // Update likes and dislikes in Firestore
  Future<void> updateLikesDislikes() async {
    final commentRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(id);
    await commentRef.update({
      'likes': likes,
      'dislikes': dislikes,
    });
  }

  // Static method to create a comment from Firestore document
  static Comment fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      videoId: data['videoId'],
      userId: data['userId'],
      username: data['username'], // Retrieve username from Firestore
      profilePictureUrl: data['profilePictureUrl'] ??
          'URL_TO_DEFAULT_IMAGE', // Default image if not found
      content: data['content'],
      timestamp: data['timestamp'],
      likes: Map<String, bool>.from(data['likes'] ?? {}),
      dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
    );
  }

  // Static method to fetch user profile picture from Firestore
  static Future<String> fetchUserProfilePicture(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data()!['profilePictureUrl'] ??
          'URL_TO_DEFAULT_IMAGE'; // Return profile picture URL or default
    }
    return 'URL_TO_DEFAULT_IMAGE'; // Default image if user not found
  }
}
