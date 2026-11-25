import 'dart:io';

import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'config.dart';
import 'crud_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  bool showFavoritesOnly = false;

  // Opens the Add dialog (item == null) or the Edit dialog (item given).
  Future<void> _openDialog({Item? item}) async {
    final result = await showDialog<_DialogResult>(
      context: context,
      builder: (_) => _ItemDialog(service: service, item: item),
    );
    if (result == null) return; // cancelled

    if (item == null) {
      await service.addItem(
        result.name,
        result.quantity,
        imageUrl: result.imageUrl,
      );
    } else {
      await service.updateItem(item.id, result.name, result.quantity);
    }
  }

  Future<void> _confirmDelete(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (ok == true) await service.deleteItem(item.id);
  }

  void _logout() {
    AuthService().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      appBar: AppBar(
        title: const Text('Firebase | $kLastName'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // FAVORITES FILTER
          IconButton(
            tooltip: 'Show favorites only',
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () =>
                setState(() => showFavoritesOnly = !showFavoritesOnly),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<Item>>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = snapshot.data!;
          if (showFavoritesOnly) {
            items = items.where((i) => i.favorite).toList();
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                showFavoritesOnly ? 'No favorites yet.' : 'No items yet. Tap +',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final imageUrl = item.imageUrl;
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  // Image saved in Cloudinary (URL stored in Firestore)
                  leading: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image, size: 40),
                          ),
                        )
                      : null,
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Quantity ${item.quantity}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          item.favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.favorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () =>
                            service.toggleFavorite(item.id, item.favorite),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _openDialog(item: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DialogResult {
  final String name;
  final int quantity;
  final String? imageUrl;
  const _DialogResult(this.name, this.quantity, this.imageUrl);
}

/// Add / Edit dialog. It is its own widget so it disposes its controllers
/// safely (avoids the red "_dependents.isEmpty" error screen).
/// Add mode can pick + upload an image; Edit mode is unchanged (name/quantity).
class _ItemDialog extends StatefulWidget {
  final CrudService service;
  final Item? item;
  const _ItemDialog({required this.service, this.item});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController qtyCtrl;

  File? selectedImageFile;
  String? selectedImageUrl;
  bool uploading = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    qtyCtrl = TextEditingController(
      text: widget.item == null ? '' : widget.item!.quantity.toString(),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => uploading = true);
    try {
      final picked = await widget.service.pickImageForAddItem();
      if (picked != null && mounted) {
        setState(() {
          selectedImageFile = picked.file;
          selectedImageUrl = picked.url;
        });
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _submit() {
    final name = nameCtrl.text.trim();
    final qty = int.tryParse(qtyCtrl.text.trim());
    if (name.isEmpty || qty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name and a whole-number quantity.'),
        ),
      );
      return;
    }
    Navigator.pop(context, _DialogResult(name, qty, selectedImageUrl));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Item' : 'Add Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (!isEdit) ...[
              const SizedBox(height: 10),
              if (selectedImageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedImageFile!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              uploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Image'),
                      onPressed: _pickImage,
                    ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isEdit ? Colors.orange : Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Disabled while an image is still uploading.
          onPressed: uploading ? null : _submit,
          child: Text(isEdit ? 'Edit' : 'Save'),
        ),
      ],
    );
  }
}