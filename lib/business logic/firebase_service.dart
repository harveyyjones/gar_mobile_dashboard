import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/models/liked_items_model.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Added Firebase Auth instance

  // Alternative method using doc() directly if you have the ID
  Future<WholesalerModel?> fetchWholesalerByIdDirect(String salerId) async {
    // New method added
    try {
      DocumentSnapshot doc = await _firestore
          .collection('sellers') // Updated collection name
          .doc(salerId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return WholesalerModel.fromFirestore(data, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching wholesaler: $e');
      throw Exception('Failed to fetch wholesaler data');
    }
  }

  // Stream version for real-time updates
  Stream<WholesalerModel?> wholesalerStream(String salerId) {
    // New method added
    return _firestore
        .collection('sellers') // Updated collection name
        .doc(salerId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return WholesalerModel.fromFirestore(data, doc.id);
      }
      return null;
    });
  }

  Future<List<Product>> fetchAllProductsWithSalerId(String sellerId) async {
    try {
      print('Fetching products for seller: $sellerId'); // Debug log
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .doc(sellerId)
          .collection('product_items')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure seller ID is included in the data
        data['seller_id'] = sellerId; // Add seller ID to the data

        Product product = Product.fromFirestore(doc);
        print(
            'Fetched product: ${product.name} with seller ID: ${product.salerId}'); // Debug log
        return product;
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<void> toggleLikeProduct(
      String productId, Map<String, dynamic> productDetails) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final likedItemsRef = userRef.collection('liked_items');
    final productDocRef =
        likedItemsRef.doc(productId); // Updated to use productDocRef

    final likedDoc = await productDocRef.get();

    if (likedDoc.exists) {
      // If the product is already liked, unlike it by deleting the document
      await productDocRef.delete();
    } else {
      // If the product is not liked, like it by creating the document
      await productDocRef.set({
        'id': productId,
        'liked_at': FieldValue.serverTimestamp(),
        ...productDetails,
      });
    }
  }

  Stream<bool> isProductLiked(String productId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_items')
        .doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> initializeLikedItems() async {
    // New method added
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final likedItemsRef = userRef.collection('liked_items');

    // Check if the liked_items collection exists
    final likedItemsDoc = await likedItemsRef.limit(1).get();
    if (likedItemsDoc.docs.isEmpty) {
      // If the collection doesn't exist, create an empty document to initialize it
      await likedItemsRef.doc('placeholder').set({'initialized': true});
    }
  }

  Stream<List<LikedProduct>> getLikedProductsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // If there's no logged in user, return an empty stream
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_items')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LikedProduct.fromFirestore(doc))
          .toList();
    });
  }

  Future<Product?> fetchProductById(String productId, String salerId) async {
    // New method added
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(salerId)
          .collection('product_items')
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null; // No product found
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  // Fetch current user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      final doc = await _firestore.collection('users').doc(userId).get();

      return doc.data();
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      // Update timestamp
      userData['last_updated'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Helper method to validate working hours // New method added
  bool isOpenNow(WorkingHours workingHours) {
    final now = DateTime.now();
    final currentDay = now.weekday;

    DayHours? dayHours;
    switch (currentDay) {
      case DateTime.monday:
        dayHours = workingHours.monday;
        break;
      case DateTime.tuesday:
        dayHours = workingHours.tuesday;
        break;
      case DateTime.wednesday:
        dayHours = workingHours.wednesday;
        break;
      case DateTime.thursday:
        dayHours = workingHours.thursday;
        break;
      case DateTime.friday:
        dayHours = workingHours.friday;
        break;
      case DateTime.saturday:
        dayHours = workingHours.saturday;
        break;
      case DateTime.sunday:
        dayHours = workingHours.sunday;
        break;
    }

    if (dayHours == null || dayHours.open.isEmpty || dayHours.close.isEmpty) {
      return false;
    }

    final openTime = _parseTimeString(dayHours!.open);
    final closeTime = _parseTimeString(dayHours.close);
    final currentTime =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);

    return currentTime.isAfter(openTime) && currentTime.isBefore(closeTime);
  }

  DateTime _parseTimeString(String timeString) {
    // New method added
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Stream<List<WholesalerModel>> wholesalersStream() {
    return _firestore.collection('sellers').snapshots().map((snapshot) {
      print('Stream received ${snapshot.docs.length} wholesalers');

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        print('Processing wholesaler: ${doc.id}');
        // Added print statement to log raw address data
        print(
            'Raw address data: ${data['adress_of_company']}, ${data['city']}, ${data['country']}');

        try {
          WholesalerModel wholesaler =
              WholesalerModel.fromFirestore(data, doc.id);
          // Added print statement to log processed address data
          print(
              'Processed address: ${wholesaler.address.addressOfCompany}, ${wholesaler.address.city}, ${wholesaler.address.country}');
          return wholesaler;
        } catch (e) {
          print('Error processing wholesaler ${doc.id}: $e');
          return _createDefaultWholesaler(doc.id, data);
        }
      }).toList();
    });
  }

  WholesalerModel _createDefaultWholesaler(
      String docId, Map<String, dynamic> data) {
    // New method added
    return WholesalerModel(
      id: docId,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      surname: '',
      nipNumber: '',
      isActive: true,
      isSellerInApp: true,
      rating: 0.0,
      totalSales: 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: AddressDetails(
        addressOfCompany: data['adress'] ?? '',
        city: data['city'] ?? '',
        country: data['country'] ?? '',
        zipNo: '',
      ),
      bankDetails: BankDetails(
        accountNumber: '',
        bankName: '',
        swiftCode: '',
      ),
      categories: [],
      paymentMethods: [],
      products: [],
      shippingMethods: [],
      workingHours: WorkingHours(
        monday: DayHours(open: '', close: ''),
        tuesday: DayHours(open: '', close: ''),
        wednesday: DayHours(open: '', close: ''),
        thursday: DayHours(open: '', close: ''),
        friday: DayHours(open: '', close: ''),
        saturday: DayHours(open: '', close: ''),
        sunday: DayHours(open: '', close: ''),
      ),
      logoUrl: '',
      sellerId: '',
    );
  }

  // Debug method to print all sellers
  Future<void> debugPrintAllSellers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('sellers').get();
      print('Total sellers in database: ${snapshot.docs.length}');
      snapshot.docs.forEach((doc) {
        print('Seller ID: ${doc.id}');
        print('Data: ${doc.data()}');
      });
    } catch (e) {
      print('Debug print error: $e');
    }
  }

  Future<List<WholesalerModel>> fetchWholesalers() async {
    // New method added
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('is_seller_in_app', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return WholesalerModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error fetching wholesalers: $e');
      rethrow;
    }
  }

  Future<WholesalerModel?> fetchWholesalerById(String wholesalerId) async {
    // New method added
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('sellers').doc(wholesalerId).get();

      if (!doc.exists) {
        return null;
      }

      return WholesalerModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error fetching wholesaler by ID: $e');
      rethrow;
    }
  }
}
