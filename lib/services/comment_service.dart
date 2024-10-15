import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:short_video_app/models/comment.dart';
import 'package:short_video_app/models/reply.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new comment to a video
  Future<void> addComment(String videoId, Comment comment) async {
    try {
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(comment.id)
          .set({
        'userId': comment.userId,
        'username': comment.username ?? '',
        'content': comment.content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': comment.likes,
        'dislikes': comment.dislikes,
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  /// Fetches comments for a video along with user profile pictures
  Future<List<Comment>> fetchComments(String videoId) async {
    try {
      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .get();

      List<Comment> comments = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String userId = data['userId'] ?? '';

        // Fetch user profile picture
        final userDoc = await _firestore.collection('users').doc(userId).get();
        String profilePictureUrl = userDoc.data()?['profilePictureUrl'] ?? '';

        comments.add(Comment(
          id: doc.id,
          videoId: videoId,
          userId: userId,
          username: data['username'] ?? '',
          profilePictureUrl: profilePictureUrl,
          content: data['content'] ?? '',
          timestamp: data['timestamp'] is Timestamp
              ? data['timestamp']
              : Timestamp.now(), // Ensure valid timestamp
          likes: Map<String, bool>.from(data['likes'] ?? {}),
          dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
        ));
      }

      return comments;
    } catch (e) {
      print("Error fetching comments: $e");
      return []; // Return an empty list on error
    }
  }

  /// Likes or dislikes a comment
  Future<void> toggleLikeDislike(
      String videoId, String commentId, String userId, bool isLike) async {
    try {
      final commentRef = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId);
      final commentDoc = await commentRef.get();

      if (commentDoc.exists) {
        final commentData = commentDoc.data()!;
        final currentLikes = Map<String, bool>.from(commentData['likes'] ?? {});
        final currentDislikes =
            Map<String, bool>.from(commentData['dislikes'] ?? {});

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

        await commentRef.update({
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });
      }
    } catch (e) {
      print("Error toggling like/dislike: $e");
    }
  }

  /// Adds a reply to a comment
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
        'username': reply.username ?? '', // Ensure username is non-null
        'content': reply.content,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
        'likes': reply.likes,
        'dislikes': reply.dislikes,
      });
    } catch (e) {
      print("Error adding reply: $e");
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
          userId: data['userId'] ?? '',
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
      print("Error fetching replies: $e");
      return []; // Return an empty list on error
    }
  }
}
