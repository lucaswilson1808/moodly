import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save user data to Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get current logged-in user's data
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;
    return await getUser(currentUserId!);
  }

  // Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update just the username
  Future<void> updateUsername(String userId, String newUsername) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'username': newUsername,
      });
    } catch (e) {
      throw Exception('Failed to update username: $e');
    }
  }

// Upload profile picture to Firebase Storage and return URL
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Create a reference to Firebase Storage
      final storageRef = _storage.ref().child('profile_pictures/$userId.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // DON'T update Firestore here - just return the URL
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

// Update profile picture for existing user (for account screen)
  Future<String> updateProfilePicture(String userId, File imageFile) async {
    try {
      final storageRef = _storage.ref().child('profile_pictures/$userId.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with new URL
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }
  // Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      // Delete from Storage
      final storageRef = _storage.ref().child('profile_pictures/$userId.jpg');
      await storageRef.delete();


    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }

  // Delete user data from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      // Delete profile picture if exists
      try {
        await deleteProfilePicture(userId);
      } catch (e) {
        // Profile picture might not exist, continue with user deletion
      }

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check username: $e');
    }
  }

  // Stream user data for real-time updates
  Stream<UserModel?> userStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}