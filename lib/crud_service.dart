import 'package:cloud_firestore/cloud_firestore.dart';

/// One document in the "items" collection.
class Item {
  final String id;
  final String name;
  final int quantity;
  final bool favorite;

  const Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.favorite,
  });

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Item(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      quantity: (data['quantity'] ?? 0) as int,
      favorite: (data['favorite'] ?? false) as bool,
    );
  }
}

/// All Firestore CRUD logic lives here (Create, Read, Update, Delete).
class CrudService {
  final CollectionReference<Map<String, dynamic>> _items =
      FirebaseFirestore.instance.collection('items');

  // READ: live list of items, oldest first.
  // The favorites filter is done in the UI, so no Firestore index is needed.
  Stream<List<Item>> getItems() {
    return _items
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(Item.fromDoc).toList());
  }

  // CREATE
  Future<void> addItem(String name, int quantity) {
    return _items.add({
      'name': name,
      'quantity': quantity,
      'favorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE name / quantity
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
