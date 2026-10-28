import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather.dart';

void main() {
  runApp(const ShoppingApp());
}

IconData iconFor(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 95) return Icons.thunderstorm;
  if (code >= 51) return Icons.water_drop;
  return Icons.help_outline;
}

class Item {
  Item(this.name);

  String name;
  bool bought = false;
  int quantity = 1;
  String note = '';
  String category = 'Food';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bought': bought,
      'quantity': quantity,
      'note': note,
      'category': category,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    final item = Item(json['name'] as String);
    item.bought = json['bought'] as bool;
    item.quantity = json['quantity'] as int;
    item.note = json['note'] as String;
    item.category = json['category'] as String;
    return item;
  }
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
  List<Item> items = [Item('Milk'), Item('Bread'), Item('Rice')];
  final controller = TextEditingController();
  String filter = 'All';

  Weather? weather;
  bool weatherLoading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    loadItems();
    loadWeather();
  }

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((item) => item.toJson()).toList();
    await prefs.setString('items', jsonEncode(list));
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('items');
    if (saved != null) {
      final list = jsonDecode(saved) as List;
      setState(() {
        items = list
            .map((x) => Item.fromJson(x as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> loadWeather() async {
    try {
      final result = await fetchWeather();
      setState(() {
        weather = result;
        weatherLoading = false;
        weatherError = null;
      });
    } catch (e) {
      setState(() {
        weatherLoading = false;
        weatherError =
            'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void retryWeather() {
    setState(() {
      weatherLoading = true;
      weatherError = null;
    });
    loadWeather();
  }

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
      saveItems();
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
    saveItems();
    controller.clear();
  }

  void removeItem(Item item) {
    final index = items.indexOf(item);
    setState(() {
      items.remove(item);
    });
    saveItems();
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
            saveItems();
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

  Widget weatherStrip() {
    if (weatherLoading) {
      return const Card(
        margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Loading the weather...'),
        ),
      );
    }

    if (weatherError != null) {
      return Card(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: ListTile(
          leading: const Icon(Icons.wifi_off),
          title: Text(weatherError!),
          trailing: FilledButton(
            onPressed: retryWeather,
            child: const Text('Retry'),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ListTile(
        leading: Icon(iconFor(weather!.code), size: 36),
        title: Text(
          'Kigali ${weather!.temperature.round()}°C · ${describe(weather!.code)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Humidity ${weather!.humidity}% · Wind ${weather!.wind} km/h',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = items.where((item) => !item.bought).length;

    final toBuy = items.where((item) => !item.bought).toList();
    final bought = items.where((item) => item.bought).toList();

    final List<Item> shown;
    if (filter == 'To buy') {
      shown = toBuy;
    } else if (filter == 'Bought') {
      shown = bought;
    } else {
      shown = [...toBuy, ...bought];
    }

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
              saveItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          weatherStrip(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filter == 'All',
                  onSelected: (_) {
                    setState(() {
                      filter = 'All';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('To buy'),
                  selected: filter == 'To buy',
                  onSelected: (_) {
                    setState(() {
                      filter = 'To buy';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bought'),
                  selected: filter == 'Bought',
                  onSelected: (_) {
                    setState(() {
                      filter = 'Bought';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Your list is empty'))
                : shown.isEmpty
                ? const Center(child: Text('Nothing here'))
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final item = shown[index];
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
                        subtitle: Text(
                          item.note.isEmpty
                              ? item.category
                              : '${item.category} · ${item.note}',
                        ),
                        onTap: () {
                          setState(() {
                            item.bought = !item.bought;
                          });
                          saveItems();
                        },
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(item: item),
                            ),
                          ).then((_) {
                            setState(() {});
                            saveItems();
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
                                  saveItems();
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
                                saveItems();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => removeItem(item),
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

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final nameController = TextEditingController();
  final noteController = TextEditingController();
  String category = 'Food';

  @override
  void initState() {
    super.initState();
    nameController.text = widget.item.name;
    noteController.text = widget.item.note;
    category = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Type a name first')));
      return;
    }
    widget.item.name = name;
    widget.item.note = noteController.text.trim();
    widget.item.category = category;
    Navigator.pop(context);
  }

  Widget categoryChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: category == label,
      onSelected: (_) {
        setState(() {
          category = label;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 24),
            const Text('Category'),
            const SizedBox(height: 8),
            Row(
              children: [
                categoryChip('Food'),
                const SizedBox(width: 8),
                categoryChip('Drinks'),
                const SizedBox(width: 8),
                categoryChip('Home'),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
