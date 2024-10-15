import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listens for changes to the user's profile document.
  Stream<DocumentSnapshot>? listenForProfileChanges(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Signs up a new user with the provided details.
  Future<String?> signUp(
      String username, String email, String password, String phone) async {
    try {
      // Check if the email is already in use
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (userQuery.docs.isNotEmpty) {
        return 'Email is already in use.';
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store user details in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'email': email,
        'phone': phone,
        'profilePictureUrl': '',
        'followers': [],
        'following': [],
      });

      // Store user details in Shared Preferences
      await _storeUserDetails(username, email, phone);

      return null; // Sign-up successful
    } catch (e) {
      return 'Sign-up failed: ${e.toString()}'; // Return error message
    }
  }

  /// Logs in an existing user.
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Fetch the user details to store in Shared Preferences
      final userDetails = await getUserDetails();
      if (userDetails.isNotEmpty) {
        await _storeUserDetails(
          userDetails['username'] ?? '',
          email,
          userDetails['phone'] ?? '',
        );
      }
      return null; // Login successful
    } catch (e) {
      return 'Login failed: ${e.toString()}'; // Return error message
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored user details
  }

  /// Stores user details in SharedPreferences.
  Future<void> _storeUserDetails(
      String username, String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('phone', phone);
  }

  /// Retrieves current user details.
  Future<Map<String, String?>> getUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>; // Cast to Map
        return {
          'uid': user.uid,
          'username': userData['username'] ?? '',
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'profilePictureUrl': userData['profilePictureUrl'] ?? '',
        };
      } else {
        return {'error': 'User document does not exist.'};
      }
    } else {
      return {'error': 'No user is currently signed in.'};
    }
  }

  /// Updates the current user's details in Firestore.
  Future<void> updateUserDetails(
      String username, String phone, String? profilePictureUrl) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': username,
        'phone': phone,
        'profilePictureUrl':
            profilePictureUrl ?? '', // Allow null or default URL
      });
      await _storeUserDetails(
          username, user.email!, phone); // Update Shared Preferences
    }
  }

  /// Retrieves user details by user ID.
  Future<Map<String, String?>> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>; // Cast to Map
        return {
          'username': userData['username'] ?? '',
          'profilePictureUrl': userData['profilePictureUrl'] ?? '',
        };
      }
      return {}; // Return an empty map if user doesn't exist
    } catch (e) {
      print("Failed to fetch user details: ${e.toString()}");
      return {};
    }
  }

  /// Retrieves profile picture and username based on video document ID.
  Future<Map<String, String?>> getVideoProfileData(String videoDocId) async {
    try {
      DocumentSnapshot videoDoc =
          await _firestore.collection('videos').doc(videoDocId).get();
      if (videoDoc.exists) {
        var videoData = videoDoc.data() as Map<String, dynamic>; // Cast to Map
        String userId = videoData['userId'] ?? '';

        // Fetch user details from the users collection
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>; // Cast to Map
          return {
            'username': userData['username'] ?? '',
            'profilePictureUrl': userData['profilePictureUrl'] ?? '',
          };
        }
      }
      return {}; // Return an empty map if video or user doesn't exist
    } catch (e) {
      print("Failed to fetch video profile data: ${e.toString()}");
      return {};
    }
  }

  /// Retrieves the current user's ID.
  String? getCurrentUserId() {
    User? user = _auth.currentUser;
    return user?.uid; // Return the user's ID or null if not signed in
  }

  /// Follows a user by user ID.
  Future<void> followUser(String userIdToFollow) async {
    String? currentUserId = getCurrentUserId();
    if (currentUserId != null) {
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayUnion([userIdToFollow]),
      });
      await _firestore.collection('users').doc(userIdToFollow).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }

  /// Unfollows a user by user ID.
  Future<void> unfollowUser(String userIdToUnfollow) async {
    String? currentUserId = getCurrentUserId();
    if (currentUserId != null) {
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([userIdToUnfollow]),
      });
      await _firestore.collection('users').doc(userIdToUnfollow).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
    }
  }

  /// Retrieves the number of followers for a user.
  Future<int> getFollowersCount(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>; // Cast to Map
        List<dynamic> followers = userData['followers'] ?? [];
        return followers.length; // Return the number of followers
      }
      return 0; // Return 0 if user doesn't exist
    } catch (e) {
      print("Failed to fetch followers count: ${e.toString()}");
      return 0; // Return 0 on error
    }
  }

  /// Retrieves the current user's profile picture URL.
  Future<String> getCurrentUserProfilePictureUrl() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        // Explicitly cast to Map<String, dynamic>
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['profilePictureUrl'] ?? '';
      }
    }
    return ''; // Return empty string if user is not signed in
  }
}
