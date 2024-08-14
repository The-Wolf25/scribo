import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userName = prefs.getString('userName') ?? '';

  runApp(ScriboApp(userName: userName));
}

class ScriboApp extends StatelessWidget {
  final String userName;

  const ScriboApp({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scribo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(userName: userName),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final String userName;

  const SplashScreen({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen(userName: userName)),
      );
    });

    return Scaffold(
      backgroundColor: Colors.purple[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scribo',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({Key? key, required this.userName}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  Color _selectedColor = Colors.purple[100]!;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    loadTasks();
    _loadThemeColor();
    _promptUserName();
  }

  Future<void> loadTasks() async {
    tasks = await TaskService.getTasks();
    filteredTasks = List.from(tasks);
    setState(() {});
  }

  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor') ?? Colors.purple[100]!.value;
    setState(() {
      _selectedColor = Color(colorValue);
    });
  }

  Future<void> _saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.value);
  }

  Future<void> _promptUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.userName.isEmpty) {
      final nameController = TextEditingController();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Welcome to Scribo!'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                await prefs.setString('userName', name);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  void addTask() {
    if (_taskController.text.isEmpty) return;
    final newTask = Task(name: _taskController.text, isDone: false);
    setState(() {
      tasks.add(newTask);
      filteredTasks.add(newTask);
    });
    TaskService.saveTasks(tasks);
    _taskController.clear();
  }

  void toggleTask(Task task) {
    setState(() {
      task.isDone = !task.isDone;
      filteredTasks = tasks
          .where((t) =>
              _searchController.text.isEmpty ||
              t.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    });
    TaskService.saveTasks(tasks);
  }

  void deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
      filteredTasks.remove(task);
    });
    TaskService.saveTasks(tasks);
  }

  void _openColorSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Theme Color'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              ColorOption(
                  color: Colors.purple,
                  colorName: 'Purple',
                  onSelect: () {
                    setState(() {
                      _selectedColor = Colors.purple;
                    });
                    _saveThemeColor(Colors.purple);
                    Navigator.of(context).pop();
                  }),
              ColorOption(
                  color: Colors.blue,
                  colorName: 'Blue',
                  onSelect: () {
                    setState(() {
                      _selectedColor = Colors.blue;
                    });
                    _saveThemeColor(Colors.blue);
                    Navigator.of(context).pop();
                  }),
              ColorOption(
                  color: Colors.green,
                  colorName: 'Green',
                  onSelect: () {
                    setState(() {
                      _selectedColor = Colors.green;
                    });
                    _saveThemeColor(Colors.green);
                    Navigator.of(context).pop();
                  }),
              ColorOption(
                  color: Colors.orange,
                  colorName: 'Orange',
                  onSelect: () {
                    setState(() {
                      _selectedColor = Colors.orange;
                    });
                    _saveThemeColor(Colors.orange);
                    Navigator.of(context).pop();
                  }),
              ColorOption(
                  color: Colors.red,
                  colorName: 'Red',
                  onSelect: () {
                    setState(() {
                      _selectedColor = Colors.red;
                    });
                    _saveThemeColor(Colors.red);
                    Navigator.of(context).pop();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void _searchTasks(String query) {
    setState(() {
      filteredTasks = tasks
          .where(
              (task) => task.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showSearchResults = query.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _selectedColor,
        title: Text(
          'Scribo',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(
                  tasks: filteredTasks,
                  onSearch: _searchTasks,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: _openColorSelector,
          ),
        ],
        toolbarHeight: 120,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 18,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 2,
                      ),
                      Text(
                        widget.userName.isNotEmpty
                            ? 'Hello, ${widget.userName}!'
                            : 'Hello There!',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: _selectedColor,
              ),
            ),
            ListTile(
                title: Text(' About Us'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => QWENTECHScreen())));
                })
            // Additional drawer items can go here
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            return TaskTile(
              task: filteredTasks[index],
              toggleTask: toggleTask,
              deleteTask: deleteTask,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Add Task'),
            content: TextField(
              controller: _taskController,
              decoration: InputDecoration(hintText: 'Enter your task here'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  addTask();
                },
                child: Text('Add'),
              ),
            ],
          ),
        ),
        child: Icon(Icons.add),
        backgroundColor: _selectedColor,
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(Task) toggleTask;
  final Function(Task) deleteTask;

  const TaskTile({
    Key? key,
    required this.task,
    required this.toggleTask,
    required this.deleteTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        task.name,
        style: TextStyle(
          fontSize: 16,
          decoration: task.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      leading: Checkbox(
        value: task.isDone,
        onChanged: (value) {
          toggleTask(task);
        },
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete,
          color: Colors.red,
          size: 25,
        ),
        onPressed: () => deleteTask(task),
      ),
    );
  }
}

class Task {
  String name;
  bool isDone;

  Task({required this.name, this.isDone = false});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'],
      isDone: json['isDone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isDone': isDone,
    };
  }
}

class TaskService {
  static Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks') ?? '[]';
    final List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((task) => Task.fromJson(task)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final Function(String) onSearch;

  TaskSearchDelegate({required this.tasks, required this.onSearch});

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Clear the search query
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Leading icon to close the search
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Results are the same as suggestions
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredTasks = tasks
        .where((task) => task.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return ListTile(
          title: Text(task.name),
          leading: Checkbox(
            value: task.isDone,
            onChanged: (value) {
              // Toggle task status
              onSearch(query);
            },
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Handle task deletion
            },
          ),
        );
      },
    );
  }
}

@override
Widget buildResults(BuildContext context) {
  return Container();
}

class ColorOption extends StatelessWidget {
  final Color color;
  final String colorName;
  final VoidCallback onSelect;

  const ColorOption({
    Key? key,
    required this.color,
    required this.colorName,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
      ),
      title: Text(colorName),
      onTap: onSelect,
    );
  }
}

// Placeholder screens (Replace these with your actual screen classes)
class QWENTECHScreen extends StatelessWidget {
  const QWENTECHScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          '',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QWENTECH',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: const Duration(seconds: 1)).slide(),
              const SizedBox(height: 20),
              const Text(
                'QWENTECH is a tech agency formed in November 2022. Our aim is to provide the following services:',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: const Duration(seconds: 1)).slide(),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceItem('App Development (Cross-Platform)'),
                  _buildServiceItem('Website Development'),
                  _buildServiceItem('Social Media Handling'),
                ],
              ),
              const SizedBox(height: 100), // Add space before the new text
              Center(
                child: const Text(
                  'App created by Prajwal R\nEmail: qwentech0@gmail.com',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: const Duration(seconds: 1))
                    .slide(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(String service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: const Duration(seconds: 1)).slide(),
    );
  }
}
