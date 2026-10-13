import 'package:flutter/material.dart';

void main() {
  runApp(const ShoppingApp());
}

class Item {
  Item(this.name);

  final String name;
  bool bought = false;
  int quantity = 1;
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const HomeScreen(title: 'Shopping List'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final items = [Item('Milk'), Item('Bread'), Item('Rice')];
  final controller = TextEditingController();

  void addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Type an item first')));
      return;
    }
    final matches = items.where(
      (item) => item.name.toLowerCase() == text.toLowerCase(),
    );
    if (matches.isNotEmpty) {
      final existing = matches.first;
      setState(() {
        existing.quantity++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${existing.name} is already on the list: now ×${existing.quantity}',
          ),
        ),
      );
      controller.clear();
      return;
    }
    setState(() {
      items.add(Item(text));
    });
    controller.clear();
  }

  void removeItem(int index) {
    final item = items[index];
    setState(() {
      items.removeAt(index);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              items.insert(index, item);
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = items.where((item) => !item.bought).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($left left)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () {
              setState(() {
                items.removeWhere((item) => item.bought);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Add an item'),
                    onSubmitted: (_) => addItem(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: addItem, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Your list is empty'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Icon(
                          item.bought
                              ? Icons.check_circle
                              : Icons.shopping_basket,
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.bought
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            item.bought = !item.bought;
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setState(() {
                                    item.quantity--;
                                  });
                                }
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() {
                                  item.quantity++;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => removeItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
