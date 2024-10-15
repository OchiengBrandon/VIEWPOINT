import 'package:cloud_firestore/cloud_firestore.dart';

class Reply {
  final String id;
  final String commentId;
  final String userId;
  final String username; // Added username field
  final String content;
  final Timestamp timestamp; // Keep the type as Timestamp
  final Map<String, bool> likes; // User ID -> true for like
  final Map<String, bool> dislikes; // User ID -> true for dislike

  Reply({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.username, // Initialize username
    required this.content,
    required this.timestamp,
    Map<String, bool>? likes,
    Map<String, bool>? dislikes,
  })  : likes = likes ?? {},
        dislikes = dislikes ?? {};

  // Method to save the reply to Firestore
  Future<void> save() async {
    final replyRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(
            commentId) // Assuming commentId is used to fetch the associated comment
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(id);

    await replyRef.set({
      'userId': userId,
      'username': username, // Save the username
      'content': content,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
      'likes': likes,
      'dislikes': dislikes,
    });
  }

  // Method to like the reply
  Future<void> like(String userId) async {
    if (!likes.containsKey(userId)) {
      // Add like and ensure dislike is removed
      likes[userId] = true;
      dislikes.remove(userId);
      await updateLikesDislikes();
    }
  }

  // Method to dislike the reply
  Future<void> dislike(String userId) async {
    if (!dislikes.containsKey(userId)) {
      // Add dislike and ensure like is removed
      dislikes[userId] = true;
      likes.remove(userId);
      await updateLikesDislikes();
    }
  }

  // Update likes and dislikes in Firestore
  Future<void> updateLikesDislikes() async {
    final replyRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(commentId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(id);

    await replyRef.update({
      'likes': likes,
      'dislikes': dislikes,
    });
  }
}
