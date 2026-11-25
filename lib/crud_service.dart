import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

import 'config.dart';

/// Result of picking + uploading an image.
class PickedImage {
  final File file;
  final String url;
  const PickedImage({required this.file, required this.url});
}

/// One document in the "items" collection.
class Item {
  final String id;
  final String name;
  final int quantity;
  final bool favorite;
  final String? imageUrl;

  const Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.favorite,
    this.imageUrl,
  });

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Item(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      quantity: (data['quantity'] ?? 0) as int,
      favorite: (data['favorite'] ?? false) as bool,
      imageUrl: data['image_url'] as String?,
    );
  }
}

/// All Firestore + Cloudinary logic lives here.
class CrudService {
  final CollectionReference<Map<String, dynamic>> _items =
      FirebaseFirestore.instance.collection('items');

  // Cloudinary: cloud name + UNSIGNED upload preset (see config.dart).
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    kCloudinaryCloudName,
    kCloudinaryUploadPreset,
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  // Opens the gallery, uploads the chosen image to Cloudinary and returns
  // the file + its secure URL. Returns null if the user cancels.
  Future<PickedImage?> pickImageForAddItem() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final file = File(picked.path);

    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return PickedImage(file: file, url: response.secureUrl);
  }

  // READ: live list of items, oldest first.
  // The favorites filter is done in the UI, so no Firestore index is needed.
  Stream<List<Item>> getItems() {
    return _items
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(Item.fromDoc).toList());
  }

  // CREATE (image_url is optional)
  Future<void> addItem(String name, int quantity, {String? imageUrl}) {
    return _items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'favorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE name / quantity (image_url is left untouched)
  Future<void> updateItem(String id, String name, int quantity) {
    return _items.doc(id).update({'name': name, 'quantity': quantity});
  }

  // UPDATE favorite flag
  Future<void> toggleFavorite(String id, bool currentValue) {
    return _items.doc(id).update({'favorite': !currentValue});
  }

  // DELETE
  Future<void> deleteItem(String id) {
    return _items.doc(id).delete();
  }
}