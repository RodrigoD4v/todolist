import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:todolist/models/Task.dart';
import 'package:todolist/screens/home_screen.dart';
import 'package:todolist/services/theme_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await dotenv.load();

  try {
    // Inicializando Hive
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    if (!Hive.isBoxOpen('tasks')) {
      await Hive.openBox<Task>('tasks');
    }
    print('Hive inicializado com sucesso.');

    // Inicializando Firebase
    await Firebase.initializeApp();
    print('Firebase inicializado com sucesso.');

    // Carregando o tema do aplicativo
    final themeService = ThemeService();
    final themeMode = await themeService.getThemeMode();

    runApp(MyApp(themeMode: themeMode));
  } catch (e, stacktrace) {
    print('Erro durante a inicialização: $e');
    print(stacktrace);
  }
}

class MyApp extends StatefulWidget {
  final ThemeMode themeMode;
  const MyApp({super.key, required this.themeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
  }

  void _changeThemeMode(ThemeMode themeMode) async {
    final themeService = ThemeService();
    await themeService.saveThemeMode(themeMode);
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: _changeThemeMode),
    );
  }
}
