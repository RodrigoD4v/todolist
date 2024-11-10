import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_task_screen.dart'; // A tela de adicionar tarefa
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    _user = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  Future<void> _loginWithGoogle() async {
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        setState(() {
          _user = user;
        });
        print('Usuário logado: ${user.displayName}');
      } else {
        print('Login cancelado');
      }
    } catch (error) {
      print("Erro ao fazer login com Google: $error");
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    setState(() {
      _user = null;
    });
    print('Usuário deslogado');
    Navigator.pop(context); // Fecha o Dialog após o logout
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

  void _showUserProfile() {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite fechar o diálogo ao clicar fora dele
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
                      Navigator.pop(context); // Fecha o Dialog
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
                  onPressed: _logout, // Chama logout e fecha o Dialog
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
          onTap: _user == null ? _loginWithGoogle : _showUserProfile, // Exibe o perfil do usuário
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
        child: _user == null
            ? Container() // Corpo vazio se o usuário não estiver logado
            : const SizedBox.shrink(), // Não exibe nada quando o usuário está logado
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega para a tela de adicionar tarefa
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Tarefa',
      ),
    );
  }
}
