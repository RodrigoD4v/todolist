import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
          _user = user; // Atualiza o estado do usuário
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List Home'),
      ),
      body: Center(
        child: _user == null
            ? ElevatedButton(
                onPressed: _loginWithGoogle,
                child: const Text('Login com Google'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Usuário logado: ${_user?.displayName}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
                ],
              ),
      ),
    );
  }
}
