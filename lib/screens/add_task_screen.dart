import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Campos para os dados adicionais da tarefa
  bool _completed = false;
  late String _id;
  late DateTime _createdAt;
  late DateTime _updatedAt;

  @override
  void initState() {
    super.initState();
    _id = DateTime.now().millisecondsSinceEpoch.toString();
    _createdAt = DateTime.now();
    _updatedAt = DateTime.now();
  }

  void _saveTask() {
    print('Título: ${_titleController.text}');
    print('Descrição: ${_descriptionController.text}');
    print('ID: $_id');
    print('Criado em: $_createdAt');
    print('Atualizado em: $_updatedAt');
    print('Completado: $_completed');

    // Fechar a tela após salvar
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
              value: _completed,
              onChanged: (value) {
                setState(() {
                  _completed = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
