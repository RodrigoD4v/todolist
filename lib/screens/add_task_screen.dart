import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:todolist/models/Task.dart';
import 'package:todolist/services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Function onTaskAdded;

  const AddTaskScreen({super.key, required this.onTaskAdded});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCompleted = false;

  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService(Hive.box<Task>('tasks'));
  }

  Future<void> _saveTask() async {
    await _taskService.saveTask(
      _titleController.text,
      _descriptionController.text,
      _isCompleted,
    );
    
    widget.onTaskAdded(); 

    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Tarefa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
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
