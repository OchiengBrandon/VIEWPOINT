import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:short_video_app/models/video.dart';
import 'package:short_video_app/models/comment.dart';
import 'package:short_video_app/services/auth_service.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Adds a new video to Firestore
  Future<void> addVideo(Video video) async {
    try {
      print("Adding video to Firestore: ${video.title}");
      await _firestore.collection('videos').doc(video.id).set(video.toMap());
      print("Video added successfully: ${video.id}");
    } catch (e) {
      print("Failed to add video: ${e.toString()}");
      rethrow;
    }
  }

  /// Fetches all videos from Firestore as a stream
  Stream<List<Video>> streamVideos() {
    print("Streaming videos from Firestore...");
    return _firestore.collection('videos').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    });
  }

  /// Fetches all videos from Firestore (one-time fetch)
  Future<List<Video>> fetchVideos() async {
    try {
      print("Fetching videos from Firestore...");
      final snapshot = await _firestore.collection('videos').get();
      print("Fetched ${snapshot.docs.length} videos.");
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    } catch (e) {
      print("Failed to fetch videos: ${e.toString()}");
      return [];
    }
  }

  /// Fetches user details based on the video document ID using userDocId
  Future<Map<String, String>> fetchUserDetailsByVideoId(String videoId) async {
    try {
      final videoSnapshot =
          await _firestore.collection('videos').doc(videoId).get();
      if (videoSnapshot.exists) {
        final userDocId = videoSnapshot.data()?['userDocId'];
        if (userDocId != null) {
          final userSnapshot =
              await _firestore.collection('users').doc(userDocId).get();
          if (userSnapshot.exists) {
            return {
              'name': userSnapshot.data()?['name'] ?? '',
              'profilePictureUrl':
                  userSnapshot.data()?['profilePictureUrl'] ?? '',
            };
          }
        }
      }
    } catch (e) {
      print("Failed to fetch user details: ${e.toString()}");
    }
    return {'name': '', 'profilePictureUrl': ''}; // Return empty if not found
  }

  /// Fetches videos liked by a specific user
  Future<List<Video>> fetchLikedVideos(String userId) async {
    try {
      print("Fetching liked videos for user: $userId");
      final snapshot = await _firestore
          .collection('videos')
          .where('likes.$userId', isEqualTo: true)
          .get();
      print("Fetched ${snapshot.docs.length} liked videos for user: $userId.");
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    } catch (e) {
      print("Failed to fetch liked videos: ${e.toString()}");
      return [];
    }
  }

  /// Fetches videos posted by a specific user
  Future<List<Video>> fetchPostedVideos(String userId) async {
    try {
      print("Fetching videos posted by user: $userId");
      final snapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .get();
      print("Fetched ${snapshot.docs.length} videos posted by user: $userId.");
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    } catch (e) {
      print("Failed to fetch posted videos: ${e.toString()}");
      return [];
    }
  }

  /// Fetches videos based on category
  Future<List<Video>> fetchVideosByCategory(String category) async {
    try {
      print("Fetching videos for category: $category");
      final snapshot = await _firestore
          .collection('videos')
          .where('category', isEqualTo: category)
          .get();
      print("Fetched ${snapshot.docs.length} videos for category: $category");
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    } catch (e) {
      print("Failed to fetch videos by category: ${e.toString()}");
      return [];
    }
  }

  /// Fetches the profile picture for a single user using userDocId
  Future<String> fetchUserProfilePicture(String userDocId) async {
    try {
      final userSnapshot =
          await _firestore.collection('users').doc(userDocId).get();
      if (userSnapshot.exists) {
        return userSnapshot.data()?['profilePictureUrl'] ?? '';
      }
    } catch (e) {
      print("Failed to fetch user profile picture: ${e.toString()}");
    }
    return '';
  }

  /// Fetches trending videos sorted by views
  Future<List<Video>> fetchTrendingVideos() async {
    try {
      print("Fetching trending videos sorted by views...");
      final snapshot = await _firestore
          .collection('videos')
          .orderBy('views', descending: true)
          .limit(10)
          .get();
      print("Fetched ${snapshot.docs.length} trending videos.");
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    } catch (e) {
      print("Failed to fetch trending videos: ${e.toString()}");
      return [];
    }
  }

  /// Fetches the latest comment for a video
  Future<Comment?> fetchLatestComment(String videoId) async {
    print("Fetching latest comment for video: $videoId");
    try {
      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        String userProfilePictureUrl =
            await fetchUserProfilePicture(data['userDocId']);
        return Comment(
          id: snapshot.docs.first.id,
          videoId: videoId,
          userId: data['userId'] ?? '',
          username: data['username'] ?? '',
          profilePictureUrl: userProfilePictureUrl,
          content: data['content'] ?? '',
          timestamp: data['timestamp'] ?? Timestamp.now(),
          likes: Map<String, bool>.from(data['likes'] ?? {}),
          dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
        );
      }
      return null;
    } catch (e) {
      print("Failed to fetch latest comment: ${e.toString()}");
      return null;
    }
  }

  /// Fetches all comments for a video as a stream
  Stream<List<Comment>> streamAllComments(String videoId) {
    print("Streaming all comments for video: $videoId");
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          videoId: videoId,
          userId: data['userId'] ?? '',
          username: data['username'] ?? '',
          profilePictureUrl: data['profilePictureUrl'] ?? '',
          content: data['content'] ?? '',
          timestamp: data['timestamp'] ?? Timestamp.now(),
          likes: Map<String, bool>.from(data['likes'] ?? {}),
          dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
        );
      }).toList();
    });
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
          currentLikes.containsKey(userId)
              ? currentLikes.remove(userId)
              : currentLikes[userId] = true;
          currentDislikes.remove(userId);
        } else {
          currentDislikes.containsKey(userId)
              ? currentDislikes.remove(userId)
              : currentDislikes[userId] = true;
          currentLikes.remove(userId);
        }

        await commentRef
            .update({'likes': currentLikes, 'dislikes': currentDislikes});
        print("Updated like/dislike for comment: $commentId");
      } else {
        print("Comment does not exist: $commentId");
      }
    } catch (e) {
      print("Failed to toggle like/dislike: ${e.toString()}");
    }
  }

  /// Likes or dislikes a video
  Future<void> toggleVideoLikeDislike(
      String videoId, String userId, bool isLike) async {
    try {
      final videoRef = _firestore.collection('videos').doc(videoId);
      final videoDoc = await videoRef.get();

      if (videoDoc.exists) {
        final videoData = videoDoc.data()!;
        final currentLikes = Map<String, bool>.from(videoData['likes'] ?? {});
        final currentDislikes =
            Map<String, bool>.from(videoData['dislikes'] ?? {});

        if (isLike) {
          currentLikes.containsKey(userId)
              ? currentLikes.remove(userId)
              : currentLikes[userId] = true;
          currentDislikes.remove(userId);
        } else {
          currentDislikes.containsKey(userId)
              ? currentDislikes.remove(userId)
              : currentDislikes[userId] = true;
          currentLikes.remove(userId);
        }

        await videoRef
            .update({'likes': currentLikes, 'dislikes': currentDislikes});
        print("Updated like/dislike for video: $videoId");
      } else {
        print("Video does not exist: $videoId");
      }
    } catch (e) {
      print("Failed to toggle like/dislike: ${e.toString()}");
    }
  }

  /// Increments the view count for a video if the user has not already viewed it
  Future<void> incrementViews(String videoId) async {
    print("Incrementing a view for a video");
    final userId = _authService.getCurrentUserId(); // Get current user ID
    if (userId == null) return; // Ensure user is logged in

    try {
      final userViewRef = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('views')
          .doc(userId); // Create a subcollection for views

      // Check if the user has already viewed the video
      final userViewDoc = await userViewRef.get();
      if (!userViewDoc.exists) {
        // Increment the view count in the video document
        final videoRef = _firestore.collection('videos').doc(videoId);
        await videoRef.update({'views': FieldValue.increment(1)});

        // Record that the user has viewed the video
        await userViewRef.set({
          'timestamp': FieldValue.serverTimestamp()
        }); // Optionally store the timestamp

        print("Incremented view count for video: $videoId");
      } else {
        print("User has already viewed the video: $videoId");
      }
    } catch (e) {
      print("Failed to increment views: ${e.toString()}");
    }
  }

  /// Searches videos by title
  Future<List<Video>> searchVideos(String query) async {
    print("Searching for videos");
    try {
      final snapshot = await _firestore
          .collection('videos')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    } catch (e) {
      print("Failed to search videos: ${e.toString()}");
      return [];
    }
  }

  /// Adds a comment to a video
  Future<void> addComment(String videoId, Comment comment) async {
    print("Adding a comment to a video");
    try {
      final commentRef = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(comment.id);
      await commentRef.set({
        'userId': comment.userId,
        'username': comment.username,
        'profilePictureUrl': comment.profilePictureUrl,
        'content': comment.content,
        'timestamp': comment.timestamp,
        'likes': comment.likes,
        'dislikes': comment.dislikes,
      });

      // Increment comments count for the video
      await incrementCommentsCount(videoId);
      print("Comment added to video: $videoId");
    } catch (e) {
      print("Failed to add comment: ${e.toString()}");
    }
  }

  /// Increments comments count for a video
  Future<void> incrementCommentsCount(String videoId) async {
    try {
      final videoRef = _firestore.collection('videos').doc(videoId);
      await videoRef.update({'commentsCount': FieldValue.increment(1)});
      print("Incremented comments count for video: $videoId");
    } catch (e) {
      print("Failed to increment comments count: ${e.toString()}");
    }
  }

  /// Fetches comments for a video (one-time fetch)
  Future<List<Comment>> fetchComments(String videoId) async {
    print("Fetching comments for video: $videoId");
    try {
      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          videoId: videoId,
          userId: data['userId'] ?? '',
          username: data['username'] ?? '',
          profilePictureUrl: data['profilePictureUrl'] ?? '',
          content: data['content'] ?? '',
          timestamp: data['timestamp'] ?? Timestamp.now(),
          likes: Map<String, bool>.from(data['likes'] ?? {}),
          dislikes: Map<String, bool>.from(data['dislikes'] ?? {}),
        );
      }).toList();
    } catch (e) {
      print("Failed to fetch comments for video: ${e.toString()}");
      return [];
    }
  }

  /// Streams videos by category
  Stream<List<Video>> streamVideosByCategory(String category) {
    print("Streaming videos for category: $category");
    return _firestore
        .collection('videos')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Video.fromMap(doc.data(), doc.id, doc.data()['userDocId'] ?? ''))
          .toList();
    });
  }

  /// Streams user details based on userDocId from a video
  Stream<Map<String, String>> streamUserDetailsByVideoId(String videoId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .snapshots()
        .asyncMap((videoSnapshot) async {
      if (videoSnapshot.exists) {
        final userDocId = videoSnapshot.data()?['userDocId'];
        if (userDocId != null) {
          final userSnapshot =
              await _firestore.collection('users').doc(userDocId).get();
          if (userSnapshot.exists) {
            return {
              'name': userSnapshot.data()?['username'] ?? '',
              'profilePictureUrl':
                  userSnapshot.data()?['profilePictureUrl'] ?? '',
              'userId': userSnapshot.id, // Fetching userId here
            };
          }
        }
      }
      return {
        'name': '',
        'profilePictureUrl': '',
        'userId': ''
      }; // Return empty if not found
    });
  }
}
