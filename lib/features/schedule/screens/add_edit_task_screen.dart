import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_model.dart';
import '../providers/schedule_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _plantName = '';
  String _taskType = 'Watering';
  DateTime _dueDate = DateTime.now();
  String _notes = '';
  bool _isLoading = false;

  final List<String> _taskTypes = ['Watering', 'Fertilizing', 'Pruning', 'Repotting', 'Misting'];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _plantName = widget.task!.plantName;
      _taskType = widget.task!.taskType;
      _dueDate = widget.task!.dueDate;
      _notes = widget.task!.notes;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (timePicked != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final userId = context.read<AuthProvider>().user?.uid ?? '';

      final task = TaskModel(
        id: widget.task?.id ?? '',
        userId: userId,
        plantId: widget.task?.plantId ?? 'general',
        plantName: _plantName,
        taskType: _taskType,
        dueDate: _dueDate,
        notes: _notes,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      try {
        if (widget.task == null) {
          await context.read<ScheduleProvider>().addTask(task);
        } else {
          await context.read<ScheduleProvider>().updateTask(task);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving task: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteTask() async {
    if (widget.task != null) {
      await context.read<ScheduleProvider>().deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Schedule' : 'Edit Schedule'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _plantName,
                decoration: const InputDecoration(labelText: 'Plant Name / Target'),
                validator: (value) => value!.isEmpty ? 'Please enter plant name' : null,
                onSaved: (value) => _plantName = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _taskType,
                decoration: const InputDecoration(labelText: 'Task Type'),
                items: _taskTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _taskType = value!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                title: Text('Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
                onSaved: (value) => _notes = value ?? '',
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveTask,
                child: const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}