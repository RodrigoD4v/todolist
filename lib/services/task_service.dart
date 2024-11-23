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

  // Função para sincronizar as tarefas após o login
  Future<void> syncTasksAfterLogin() async {
    if (_auth.currentUser != null) {
      await syncTasksWithApi();
    }
  }

  // Função para enviar as tarefas para a API
  Future<void> syncTasksWithApi() async {
    var tasks = taskBox.values.toList();
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
            Uri.parse('$apiUrl/tasks/${user.uid}'),
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

        } catch (error) {
          print("Erro ao enviar tarefa para a API: $error");
        }
      } 
    }
  }

  // Função para salvar tarefa no Hive
  Future<void> saveTask(String title, String description, bool isCompleted) async {
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

  // Função para excluir tarefa
  Future<void> deleteTask(String taskId) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        String? apiUrl = dotenv.env['API_URL'];

        if (apiUrl == null || apiUrl.isEmpty) {
          return;
        }

        final response = await http.delete(
          Uri.parse('$apiUrl/tasks/${user.uid}/$taskId'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {         
          // Excluir tarefa localmente do Hive
          final taskIndex = taskBox.values.toList().indexWhere((task) => task.id == taskId);
          if (taskIndex != -1) {
            await taskBox.deleteAt(taskIndex);
          }
        } 
      } catch (error) {
        print("Erro ao excluir tarefa: $error");
      }
    } 
  }

  // Função para editar tarefa localmente ou na API se necessário
  Future<void> editTask(String taskId, String newTitle, String newDescription, bool newCompletionStatus) async {
    final taskIndex = taskBox.values.toList().indexWhere((task) => task.id == taskId);

    if (taskIndex != -1) {
      final taskToUpdate = taskBox.getAt(taskIndex);
      taskToUpdate!.title = newTitle;
      taskToUpdate.description = newDescription;
      taskToUpdate.completed = newCompletionStatus;
      taskToUpdate.updatedAt = DateTime.now();

      await taskBox.putAt(taskIndex, taskToUpdate);

      // Sincroniza com a API
      await syncTasksWithApi();
    } else {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          String? apiUrl = dotenv.env['API_URL'];
          if (apiUrl == null || apiUrl.isEmpty) {
            print("URL da API não configurada.");
            return;
          }

          final updatedTask = {
            'id': taskId,
            'title': newTitle,
            'description': newDescription,
            'completed': newCompletionStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          };

          final response = await http.put(
            Uri.parse('$apiUrl/tasks/${user.uid}/$taskId'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updatedTask),
          );

        } catch (error) {
          print("Erro ao fazer PUT na API: $error");
        }
      }
    }
  }
}