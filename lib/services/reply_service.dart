import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:short_video_app/models/reply.dart';

class ReplyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new reply to a comment
  Future<void> addReply(String videoId, String commentId, Reply reply) async {
    try {
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(reply.id)
          .set({
        'userId': reply.userId,
        'username': reply.username, // Save the username
        'content': reply.content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': reply.likes,
        'dislikes': reply.dislikes,
      });
    } catch (e) {
      print("Error adding reply: $e"); // Handle error appropriately
    }
  }

  /// Fetches replies for a comment
  Future<List<Reply>> fetchReplies(String videoId, String commentId) async {
    try {
      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Reply(
          id: doc.id,
          commentId: commentId,
          userId: data['userId'],
          username: data['username'] ?? '', // Fetch the username
          content: data['content'] ?? '',
          timestamp: data['timestamp'] is Timestamp
              ? data['timestamp']
              : Timestamp.now(), // Ensure valid timestamp
          likes: Map<String, bool>.from(data['likes'] ?? {}),
          dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
        );
      }).toList();
    } catch (e) {
      print("Error fetching replies: $e"); // Handle error appropriately
      return [];
    }
  }

  /// Likes or dislikes a reply
  Future<void> toggleLikeDislike(String videoId, String commentId,
      String replyId, String userId, bool isLike) async {
    try {
      final replyRef = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId);
      final replyDoc = await replyRef.get();

      if (replyDoc.exists) {
        final replyData = replyDoc.data()!;
        final currentLikes = Map<String, bool>.from(replyData['likes'] ?? {});
        final currentDislikes =
            Map<String, bool>.from(replyData['dislikes'] ?? {});

        if (isLike) {
          if (currentLikes.containsKey(userId)) {
            currentLikes.remove(userId);
          } else {
            currentLikes[userId] = true;
            currentDislikes.remove(userId);
          }
        } else {
          if (currentDislikes.containsKey(userId)) {
            currentDislikes.remove(userId);
          } else {
            currentDislikes[userId] = true;
            currentLikes.remove(userId);
          }
        }

        await replyRef.update({
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });
      }
    } catch (e) {
      print("Error toggling like/dislike: $e"); // Handle error appropriately
    }
  }
}
