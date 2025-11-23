import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/coffee_bag.dart';
import '../models/cup.dart';
import '../models/shared_cup.dart';

/// Cloud synchronization and authentication service using Firebase.
///
/// **Premium Feature:** This service is only available to paid users.
///
/// Provides comprehensive Firebase integration for:
/// - **Authentication**: Email/password signup, login, password reset
/// - **Cloud Sync**: Automatic data backup to Firestore
/// - **Multi-Device**: Real-time sync across user devices
/// - **Sharing**: QR code-based cup/recipe sharing via Firestore
///
/// **Architecture Pattern:** Singleton
///
/// **Graceful Degradation:**
/// - Initialize returns false if Firebase not configured
/// - App continues in offline-only mode without Firebase
/// - All methods check [isAvailable] before operations
/// - User-friendly error messages for all failures
///
/// **Firestore Data Structure:**
/// ```
/// /users/{uid}/
///   - (user profile document)
///   /bags/{bagId}/
///     - (coffee bag document)
///   /cups/{cupId}/
///     - (cup/brew document)
/// /shared/{shareId}/
///   - (shared cup data for QR codes)
/// ```
///
/// **Error Handling:**
/// All methods throw exceptions with user-friendly messages:
/// - FirebaseAuthException → Clear auth error messages
/// - FirebaseException → Firestore operation errors
/// - Generic exceptions → "Try again later" messages
///
/// **Setup Required:**
/// 1. Create Firebase project at https://console.firebase.google.com/
/// 2. Add Android/iOS/Web apps to Firebase project
/// 3. Download and add configuration files:
///    - Android: `google-services.json` → `android/app/`
///    - iOS: `GoogleService-Info.plist` → `ios/Runner/`
/// 4. Enable Firebase services in console:
///    - Authentication (Email/Password provider)
///    - Cloud Firestore Database
///    - Firebase Storage (for photos)
/// 5. Configure security rules (see SETUP_INSTRUCTIONS.md)
/// 6. App will automatically detect Firebase availability
///
/// **Usage Examples:**
///
/// **Authentication:**
/// ```dart
/// final firebase = FirebaseService();
/// await firebase.initialize();
///
/// if (firebase.isAvailable) {
///   try {
///     final uid = await firebase.signUp(email, password);
///     print('Signed up with UID: $uid');
///   } catch (e) {
///     print('Error: $e'); // User-friendly message
///   }
/// }
/// ```
///
/// **Syncing Data:**
/// ```dart
/// // Sync single bag
/// await firebase.syncBag(bag);
///
/// // Sync all data
/// await firebase.syncAllToCloud(
///   user: userProfile,
///   bags: allBags,
///   cups: allCups,
/// );
///
/// // Load from cloud
/// final data = await firebase.loadAllFromCloud(userId);
/// ```
///
/// **Real-time Listening:**
/// ```dart
/// final bagsStream = firebase.watchBags(userId);
/// bagsStream?.listen((bags) {
///   print('Bags updated: ${bags.length}');
/// });
/// ```
///
/// **Sharing:**
/// ```dart
/// // Share cup (returns share ID for QR code)
/// final shareId = await firebase.shareCup(cup, username);
///
/// // Receive shared cup
/// final sharedCup = await firebase.receiveSharedCup(shareId, userId);
/// ```
///
/// **See Also:**
/// - [DatabaseService] for local offline storage
/// - [FIREBASE_BACKEND_ACTIVATED.md] for implementation details
/// - [SETUP_INSTRUCTIONS.md] for Firebase setup guide
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  FirebaseAuth? _auth;
  // ignore: unused_field
  FirebaseFirestore? _firestore; // Used in commented TODO sections, will be active when Firebase is configured

  bool _isInitialized = false;

  /// Check if Firebase is configured and available
  bool get isAvailable => _isInitialized;

  /// Get current Firebase user
  User? get currentUser => _auth?.currentUser;

  /// Initialize Firebase and set up authentication and Firestore instances.
  ///
  /// **Returns:** `true` if Firebase initialized successfully, `false` otherwise.
  ///
  /// **Graceful Failure:**
  /// - If Firebase is not configured, returns `false` without crashing
  /// - App continues in offline-only mode
  /// - All Firebase methods will check [isAvailable] before executing
  ///
  /// **Called From:** `main.dart` during app initialization
  ///
  /// **Example:**
  /// ```dart
  /// final firebase = FirebaseService();
  /// final success = await firebase.initialize();
  /// if (success) {
  ///   print('Premium features available');
  /// } else {
  ///   print('Running in offline mode');
  /// }
  /// ```
  Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      print('Firebase initialized successfully');
      return true;
    } catch (e) {
      print('Firebase not configured. Running in local-only mode.');
      print('Error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Create a new user account with email and password.
  ///
  /// **Parameters:**
  /// - [email]: User's email address
  /// - [password]: User's password (minimum 6 characters recommended)
  ///
  /// **Returns:** Firebase user UID on success
  ///
  /// **Throws:**
  /// - `Exception('email-already-in-use')` - Email is already registered
  /// - `Exception('invalid-email')` - Email format is invalid
  /// - `Exception('weak-password')` - Password is too weak
  /// - `Exception('operation-not-allowed')` - Email/password auth not enabled
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   final uid = await firebase.signUp('user@example.com', 'password123');
  ///   print('Created user: $uid');
  ///   // Update UserProfile.firebaseUid and set isPaid = true
  /// } catch (e) {
  ///   print('Signup failed: $e'); // User-friendly message
  /// }
  /// ```
  Future<String?> signUp(String email, String password) async {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Please check your setup.');
    }

    try {
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User signed up successfully: ${userCredential.user?.uid}');
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during signup: ${e.code}');

      // Provide user-friendly error messages
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('This email is already registered. Please login instead.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled. Please contact support.');
        case 'weak-password':
          throw Exception('Password is too weak. Please use a stronger password.');
        default:
          throw Exception('Signup failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Unexpected signup error: $e');
      throw Exception('Signup failed. Please try again later.');
    }
  }

  /// Sign in existing user
  Future<String?> signIn(String email, String password) async {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Please check your setup.');
    }

    try {
      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during login: ${e.code}');

      // Provide user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email. Please sign up first.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'user-disabled':
          throw Exception('This account has been disabled. Please contact support.');
        case 'invalid-credential':
          throw Exception('Invalid email or password. Please check and try again.');
        default:
          throw Exception('Login failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Unexpected login error: $e');
      throw Exception('Login failed. Please try again later.');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (!_isInitialized) return;

    try {
      await _auth?.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Please check your setup.');
    }

    try {
      await _auth!.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during password reset: ${e.code}');

      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        default:
          throw Exception('Password reset failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Unexpected password reset error: $e');
      throw Exception('Password reset failed. Please try again later.');
    }
  }

  // ============================================================================
  // USER PROFILE SYNC
  // ============================================================================

  /// Sync user profile to Firestore
  Future<bool> syncUserProfile(UserProfile profile) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot sync: Firebase not initialized or user not logged in');
      return false;
    }

    try {
      await _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .set(profile.toJson(), SetOptions(merge: true));

      print('User profile synced successfully for user: ${currentUser!.uid}');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore error syncing user profile: ${e.code} - ${e.message}');
      throw Exception('Failed to sync profile: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error syncing user profile: $e');
      throw Exception('Failed to sync profile. Please try again later.');
    }
  }

  /// Load user profile from Firestore
  Future<UserProfile?> loadUserProfile(String userId) async {
    if (!_isInitialized) {
      print('Cannot load: Firebase not initialized');
      return null;
    }

    try {
      final doc = await _firestore!
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        print('User profile loaded successfully for user: $userId');
        return UserProfile.fromJson(doc.data()!);
      }

      print('User profile not found for user: $userId');
      return null;
    } on FirebaseException catch (e) {
      print('Firestore error loading user profile: ${e.code} - ${e.message}');
      throw Exception('Failed to load profile: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error loading user profile: $e');
      throw Exception('Failed to load profile. Please try again later.');
    }
  }

  // ============================================================================
  // COFFEE BAG SYNC
  // ============================================================================

  /// Sync coffee bag to Firestore
  Future<bool> syncBag(CoffeeBag bag) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot sync bag: Firebase not initialized or user not logged in');
      return false;
    }

    try {
      await _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bags')
          .doc(bag.id)
          .set(bag.toJson(), SetOptions(merge: true));

      print('Bag synced successfully: ${bag.id}');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore error syncing bag: ${e.code} - ${e.message}');
      throw Exception('Failed to sync bag: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error syncing bag: $e');
      throw Exception('Failed to sync bag. Please try again later.');
    }
  }

  /// Load all bags for user from Firestore
  Future<List<CoffeeBag>> loadBags(String userId) async {
    if (!_isInitialized) {
      print('Cannot load bags: Firebase not initialized');
      return [];
    }

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('bags')
          .get();

      final bags = snapshot.docs
          .map((doc) => CoffeeBag.fromJson(doc.data()))
          .toList();

      print('Loaded ${bags.length} bags for user: $userId');
      return bags;
    } on FirebaseException catch (e) {
      print('Firestore error loading bags: ${e.code} - ${e.message}');
      throw Exception('Failed to load bags: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error loading bags: $e');
      throw Exception('Failed to load bags. Please try again later.');
    }
  }

  /// Delete bag from Firestore
  Future<bool> deleteBag(String bagId) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot delete bag: Firebase not initialized or user not logged in');
      return false;
    }

    try {
      await _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bags')
          .doc(bagId)
          .delete();

      print('Bag deleted successfully: $bagId');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore error deleting bag: ${e.code} - ${e.message}');
      throw Exception('Failed to delete bag: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error deleting bag: $e');
      throw Exception('Failed to delete bag. Please try again later.');
    }
  }

  // ============================================================================
  // CUP SYNC
  // ============================================================================

  /// Sync cup to Firestore
  Future<bool> syncCup(Cup cup) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot sync cup: Firebase not initialized or user not logged in');
      return false;
    }

    try {
      await _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cups')
          .doc(cup.id)
          .set(cup.toJson(), SetOptions(merge: true));

      print('Cup synced successfully: ${cup.id}');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore error syncing cup: ${e.code} - ${e.message}');
      throw Exception('Failed to sync cup: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error syncing cup: $e');
      throw Exception('Failed to sync cup. Please try again later.');
    }
  }

  /// Load all cups for a bag from Firestore
  Future<List<Cup>> loadCupsForBag(String bagId) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot load cups: Firebase not initialized or user not logged in');
      return [];
    }

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cups')
          .where('bagId', isEqualTo: bagId)
          .get();

      final cups = snapshot.docs
          .map((doc) => Cup.fromJson(doc.data()))
          .toList();

      print('Loaded ${cups.length} cups for bag: $bagId');
      return cups;
    } on FirebaseException catch (e) {
      print('Firestore error loading cups: ${e.code} - ${e.message}');
      throw Exception('Failed to load cups: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error loading cups: $e');
      throw Exception('Failed to load cups. Please try again later.');
    }
  }

  /// Delete cup from Firestore
  Future<bool> deleteCup(String cupId) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot delete cup: Firebase not initialized or user not logged in');
      return false;
    }

    try {
      await _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cups')
          .doc(cupId)
          .delete();

      print('Cup deleted successfully: $cupId');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore error deleting cup: ${e.code} - ${e.message}');
      throw Exception('Failed to delete cup: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error deleting cup: $e');
      throw Exception('Failed to delete cup. Please try again later.');
    }
  }

  // ============================================================================
  // SHARING (QR CODES)
  // ============================================================================

  /// Share cup via Firestore (generates shareable link/QR)
  Future<String?> shareCup(Cup cup, String username) async {
    if (!_isInitialized || currentUser == null) {
      print('Cannot share cup: Firebase not initialized or user not logged in');
      return null;
    }

    try {
      const uuid = Uuid();
      final shareId = uuid.v4();
      final shareData = {
        'cupId': cup.id,
        'userId': cup.userId,
        'username': username,
        'cupData': cup.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore!
          .collection('shared')
          .doc(shareId)
          .set(shareData);

      print('Cup shared successfully with ID: $shareId');
      return shareId; // This can be encoded in QR code
    } on FirebaseException catch (e) {
      print('Firestore error sharing cup: ${e.code} - ${e.message}');
      throw Exception('Failed to share cup: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error sharing cup: $e');
      throw Exception('Failed to share cup. Please try again later.');
    }
  }

  /// Receive shared cup from QR code
  Future<SharedCup?> receiveSharedCup(String shareId, String receiverUserId) async {
    if (!_isInitialized) {
      print('Cannot receive cup: Firebase not initialized');
      return null;
    }

    try {
      final doc = await _firestore!
          .collection('shared')
          .doc(shareId)
          .get();

      if (!doc.exists || doc.data() == null) {
        print('Shared cup not found: $shareId');
        return null;
      }

      final data = doc.data()!;
      final cup = Cup.fromJson(data['cupData'] as Map<String, dynamic>);

      const uuid = Uuid();
      final sharedCup = SharedCup(
        id: uuid.v4(),
        originalCupId: data['cupId'] as String,
        originalUserId: data['userId'] as String,
        originalUsername: data['username'] as String,
        receivedByUserId: receiverUserId,
        cupData: cup,
        sharedAt: DateTime.now(),
      );

      print('Shared cup received successfully: $shareId');
      return sharedCup;
    } on FirebaseException catch (e) {
      print('Firestore error receiving shared cup: ${e.code} - ${e.message}');
      throw Exception('Failed to receive cup: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      print('Unexpected error receiving shared cup: $e');
      throw Exception('Failed to receive cup. Please try again later.');
    }
  }

  // ============================================================================
  // FULL SYNC (Initial sync or manual sync)
  // ============================================================================

  /// Perform a complete sync of all local data to Firestore.
  ///
  /// This is typically used for:
  /// - Initial cloud backup when user upgrades to premium
  /// - Manual "Backup Now" action in settings
  /// - Disaster recovery scenarios
  ///
  /// **Parameters:**
  /// - [user]: User profile to sync
  /// - [bags]: All coffee bags to sync
  /// - [cups]: All cups/brews to sync
  ///
  /// **Returns:** `true` if all data synced successfully, `false` on any failure
  ///
  /// **Process:**
  /// 1. Syncs user profile first
  /// 2. Iterates through all bags and syncs each
  /// 3. Iterates through all cups and syncs each
  /// 4. Logs progress to console
  ///
  /// **Note:** This can be slow for large datasets. Consider showing progress UI.
  ///
  /// **Example:**
  /// ```dart
  /// final success = await firebase.syncAllToCloud(
  ///   user: currentUser,
  ///   bags: allBags,
  ///   cups: allCups,
  /// );
  /// if (success) {
  ///   showSnackbar('All data backed up to cloud');
  /// }
  /// ```
  Future<bool> syncAllToCloud({
    required UserProfile user,
    required List<CoffeeBag> bags,
    required List<Cup> cups,
  }) async {
    if (!_isInitialized || currentUser == null) return false;

    try {
      print('Starting full sync to cloud...');

      // Sync user profile
      await syncUserProfile(user);

      // Sync all bags
      for (final bag in bags) {
        await syncBag(bag);
      }

      // Sync all cups
      for (final cup in cups) {
        await syncCup(cup);
      }

      print('Full sync completed');
      return true;
    } catch (e) {
      print('Error during full sync: $e');
      return false;
    }
  }

  /// Load all data from Firestore
  Future<Map<String, dynamic>> loadAllFromCloud(String userId) async {
    if (!_isInitialized) return {};

    try {
      print('Loading all data from cloud...');

      final user = await loadUserProfile(userId);
      final bags = await loadBags(userId);

      // Load cups for all bags
      final allCups = <Cup>[];
      for (final bag in bags) {
        final cups = await loadCupsForBag(bag.id);
        allCups.addAll(cups);
      }

      return {
        'user': user,
        'bags': bags,
        'cups': allCups,
      };
    } catch (e) {
      print('Error loading from cloud: $e');
      return {};
    }
  }

  // ============================================================================
  // REALTIME LISTENERS (for multi-device sync)
  // ============================================================================

  /// Create a real-time stream of coffee bags for multi-device sync.
  ///
  /// **Returns:** Stream of coffee bag lists that updates automatically when
  /// Firestore data changes, or `null` if Firebase not initialized.
  ///
  /// **Use Case:**
  /// - Real-time synchronization across multiple devices
  /// - Automatically reflects changes made on other devices
  /// - Updates UI when bags are added/modified/deleted remotely
  ///
  /// **Parameters:**
  /// - [userId]: Firebase UID of the user whose bags to watch
  ///
  /// **Example:**
  /// ```dart
  /// final bagsStream = firebase.watchBags(user.firebaseUid);
  /// if (bagsStream != null) {
  ///   bagsStream.listen((bags) {
  ///     // Update local database with cloud changes
  ///     for (final bag in bags) {
  ///       await db.updateBag(bag);
  ///     }
  ///     // Refresh UI
  ///     ref.read(bagsProvider.notifier).refresh();
  ///   });
  /// }
  /// ```
  ///
  /// **Important:** Remember to cancel the stream subscription when not needed
  /// to avoid memory leaks.
  Stream<List<CoffeeBag>>? watchBags(String userId) {
    if (!_isInitialized || currentUser == null) {
      print('Cannot watch bags: Firebase not initialized or user not logged in');
      return null;
    }

    try {
      return _firestore!
          .collection('users')
          .doc(userId)
          .collection('bags')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CoffeeBag.fromJson(doc.data()))
              .toList());
    } catch (e) {
      print('Error watching bags: $e');
      return null;
    }
  }

  /// Listen to cup changes in realtime
  Stream<List<Cup>>? watchCupsForBag(String bagId) {
    if (!_isInitialized || currentUser == null) {
      print('Cannot watch cups: Firebase not initialized or user not logged in');
      return null;
    }

    try {
      return _firestore!
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cups')
          .where('bagId', isEqualTo: bagId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Cup.fromJson(doc.data()))
              .toList());
    } catch (e) {
      print('Error watching cups: $e');
      return null;
    }
  }
}
