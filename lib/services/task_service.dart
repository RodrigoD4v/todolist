import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:todolist/models/Task.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TaskService {
  final Box<Task> taskBox;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskService(this.taskBox);

  // Função para enviar as tarefas para a API
  Future<void> syncTasksWithApi() async {
    var tasks = taskBox.values.toList(); // Pega todas as tarefas do Hive
    String? apiUrl = dotenv.env['API_URL'];

     if (apiUrl == null || apiUrl.isEmpty) {
      return;
    }

    for (var task in tasks) {
      User? user = _auth.currentUser;

      if (user != null) {
        try {
          // Envia a tarefa para a API com o UID do usuário logado
          final response = await http.post(
            Uri.parse(
                '$apiUrl/tasks/${user.uid}'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'createdAt': task.createdAt.toIso8601String(),
              'updatedAt': task.updatedAt.toIso8601String(),
              'completed': task.completed,
            }),
          );

          if (response.statusCode == 200) {
            print("Tarefa sincronizada com sucesso.");
          } else {
            print("Erro ao sincronizar tarefa: ${response.body}");
          }
        } catch (error) {
          print("Erro ao enviar tarefa para a API: $error");
        }
      } else {
        print("Usuário não está autenticado.");
      }
    }
  }

  // Salvar tarefa no Hive
  Future<void> saveTask(
      String title, String description, bool isCompleted) async {
    var uuid = const Uuid();
    final newTask = Task(
      id: uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      completed: isCompleted,
    );

    // Adicionar a tarefa no Hive
    await taskBox.add(newTask);

    // Chama a função para sincronizar com a API
    await syncTasksWithApi();
  }
}
