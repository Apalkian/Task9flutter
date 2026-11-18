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
      builder: (_) => _ItemDialog(item: item),
    );
    if (result == null) return; // cancelled

    if (item == null) {
      await service.addItem(result.name, result.quantity);
    } else {
      await service.updateItem(item.id, result.name, result.quantity);
    }
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
              return Card(
                child: ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Quantity ${item.quantity}'),
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
                        onPressed: () => service.deleteItem(item.id),
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
  const _DialogResult(this.name, this.quantity);
}

/// Add / Edit dialog. It is its own widget so it disposes its controllers
/// safely (avoids the red "_dependents.isEmpty" error screen).
class _ItemDialog extends StatefulWidget {
  final Item? item;
  const _ItemDialog({this.item});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController qtyCtrl;

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

  void _submit() {
    final name = nameCtrl.text.trim();
    final qty = int.tryParse(qtyCtrl.text.trim());
    if (name.isEmpty || qty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and a whole-number quantity.')),
      );
      return;
    }
    Navigator.pop(context, _DialogResult(name, qty));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Item' : 'Add Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
          ),
          onPressed: _submit,
          child: Text(isEdit ? 'Edit' : 'Save'),
        ),
      ],
    );
  }
}