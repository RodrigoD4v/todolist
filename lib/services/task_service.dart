import 'package:hive/hive.dart';
import 'package:todolist/models/Task.dart';
import 'package:uuid/uuid.dart';

class TaskService {
  final Box<Task> taskBox;

  TaskService(this.taskBox);

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

    await taskBox.add(newTask);
  }
}

