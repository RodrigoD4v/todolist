import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:todolist/models/Task.dart';
import 'package:todolist/services/task_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final Function onTaskUpdated;

  const EditTaskScreen({super.key, required this.task, required this.onTaskUpdated});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCompleted = false;

  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _isCompleted = widget.task.completed;
    _taskService = TaskService(Hive.box<Task>('tasks'));
  }

  Future<void> _updateTask() async {
    await _taskService.editTask(
      widget.task.id,
      _titleController.text,
      _descriptionController.text,
      _isCompleted,
    );

    widget.onTaskUpdated();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Tarefa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Completada'),
              value: _isCompleted,
              onChanged: (value) {
                setState(() {
                  _isCompleted = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
