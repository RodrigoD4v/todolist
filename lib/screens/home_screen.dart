import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/models/Task.dart';
import 'package:todolist/screens/edit_task_screen.dart';
import 'package:todolist/services/task_service.dart';
import 'add_task_screen.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  late Box<Task> _taskBox;
  late Future<List<Task>> _tasksFuture;
  String? apiUrl = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();
    _tasksFuture = Future.value([]);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _openTaskBox();
    await _checkUserStatus();

    if (_user != null) {
      final taskService = TaskService(_taskBox);
      await taskService.syncTasksAfterLogin();
    }
  }

  Future<void> _onRefresh() async {
  setState(() {
    _tasksFuture = _loadTasks();
  });
}

  Future<void> _openTaskBox() async {
    _taskBox = await Hive.openBox<Task>('tasks');
    _tasksFuture = _loadTasks();
    setState(() {});
  }

  Future<void> _checkUserStatus() async {
    _user = FirebaseAuth.instance.currentUser;
    _tasksFuture = _loadTasks();
    setState(() {});
  }

  Future<List<Task>> _loadTasks() async {
    if (_user == null) {
      return _taskBox.values.toList();
    } else {
      // Buscar tarefas do Firestore via backend Spring
      final userUid = _user!.uid;
      final response = await http.get(
        Uri.parse('$apiUrl/tasks/$userUid'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = json.decode(utf8.decode(response.bodyBytes));
        return tasksJson.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        throw Exception('Erro ao carregar tarefas');
      }
    }
  }

  // Função de login com Google
  Future<void> _loginWithGoogle() async {
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        setState(() {
          _user = user;
          _tasksFuture = _loadTasks();
        });

        final taskService = TaskService(_taskBox);
        await taskService.syncTasksAfterLogin();

        print('Usuário logado: ${user.displayName}');
      } else {
        print('Login cancelado');
      }
    } catch (error) {
      print("Erro ao fazer login com Google: $error");
    }
  }

  // Função de logout
  Future<void> _logout() async {
    await _authService.signOut();
    setState(() {
      _user = null;
      _tasksFuture = _loadTasks();
    });
    print('Usuário deslogado');
    Navigator.pop(context);
  }

  // Função de exibição do perfil do usuário
  void _showUserProfile() {
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _user?.photoURL != null
                      ? NetworkImage(_user!.photoURL!)
                      : null,
                  child: _user?.photoURL == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _user?.displayName ?? 'Nome não disponível',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.email ?? 'Email não disponível',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Divider(),
                TextButton(
                  onPressed: _logout,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.logout, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Sair'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTaskAdded() {
    setState(() {
      _tasksFuture = _loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: _showThemeDialog,
          ),
        ],
        title: GestureDetector(
          onTap: _user == null ? _loginWithGoogle : _showUserProfile, 
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                child: _user?.photoURL == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                _user == null ? 'Login' : _user!.displayName ?? 'Usuário',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: FutureBuilder<List<Task>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma tarefa salva'));
            }

            final tasks = snapshot.data!;

            return RefreshIndicator(
            onRefresh: _onRefresh, 
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          task.completed ? Icons.check_box : Icons.check_box_outline_blank,
                          color: task.completed ? Colors.green : Colors.grey,
                        ),
                        onPressed: () async {
                          await TaskService(_taskBox).editTask(
                            task.id, 
                            task.title, 
                            task.description, 
                            !task.completed, 
                          );
                          setState(() {
                            _tasksFuture = _loadTasks(); 
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Excluir tarefa ao clicar no botão
                          await TaskService(_taskBox).deleteTask(task.id);
                          setState(() {
                            _tasksFuture = _loadTasks();
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Navegar para a tela de edição
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(
                          task: task,
                          onTaskUpdated: _onRefresh,
                        ),
                      ),
                    );
                    setState(() {
                      _tasksFuture = _loadTasks();
                    });
                  },
                );
              },
            ),
          );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen(onTaskAdded: _onTaskAdded)),
          );

          if (result != null && result) {
            setState(() {
              _tasksFuture = _loadTasks();
            });
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Tarefa',
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha o tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sistema'),
                onTap: () {
                  widget.onThemeChanged(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Claro'),
                onTap: () {
                  widget.onThemeChanged(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Escuro'),
                onTap: () {
                  widget.onThemeChanged(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}