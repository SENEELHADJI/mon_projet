import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  bool _isInit = false;
  bool _isLoading = false;
  late String _taskId;

  String _selectedDateText = "Sélectionner une date et heure";
  String _priority = 'Moyenne';
  bool _hasReminder = false;
  
  // Pour conserver l'objet DateTime complet si nécessaire
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _taskId = ModalRoute.of(context)!.settings.arguments as String;
      _loadTaskData();
      _isInit = true;
    }
  }

  Future<void> _loadTaskData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance.collection('tasks').doc(_taskId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descController.text = data['description'] ?? '';
          _priority = data['priority'] ?? 'Moyenne';
          _hasReminder = data['hasReminder'] ?? false;
          
          if (data['dueDate'] != null) {
            // Si c'est un Timestamp Firestore
            if (data['dueDate'] is Timestamp) {
              _selectedDateTime = (data['dueDate'] as Timestamp).toDate();
              _selectedDateText = "${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}";
            } else {
              // Si c'est sauvegardé en String
              _selectedDateText = data['dueDate'].toString();
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar("Erreur lors du chargement de la tâche", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Sélection de la date PUIS de l'heure pour correspondre au Dashboard du jour
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF333333)),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          final hourStr = pickedTime.hour.toString().padLeft(2, '0');
          final minuteStr = pickedTime.minute.toString().padLeft(2, '0');
          _selectedDateText = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year} $hourStr:$minuteStr";
        });
      }
    }
  }

  Future<void> _updateTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Optionnel : On envoie soit le Timestamp (mieux pour trier), soit la String formatée
        dynamic dateToSave = _selectedDateTime ?? _selectedDateText;

        await FirebaseFirestore.instance.collection('tasks').doc(_taskId).update({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'priority': _priority,
          'dueDate': dateToSave, // Enregistre la date mise à jour
          'hasReminder': _hasReminder,
        });
        
        if (mounted) {
          _showSnackBar("Tâche modifiée avec succès !", Colors.green);
          
          // CRUCIAL : On coupe d'abord le chargement AVANT de fermer la page (pop)
          setState(() => _isLoading = false); 
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar("Impossible de mettre à jour la tâche.", Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Harmonisé avec le fond clair épuré
      body: SafeArea(
        child: _isLoading && _titleController.text.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF333333)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Modifier la tâche",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 24),
                      const Text("Titre de la tâche", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: "Projet Flutter",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (value) => value!.trim().isEmpty ? "Le titre ne peut pas être vide" : null,
                      ),
                      const SizedBox(height: 20),
                      const Text("Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Développer l'application...",
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Date & Heure", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          InkWell(
                            onTap: () => _selectDateTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(_selectedDateText, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF333333)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text("Priorité", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: ['Faible', 'Moyenne', 'Haute'].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _priority = value!);
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text("Rappel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Activer le rappel", style: TextStyle(fontSize: 14, color: Colors.black54)),
                          Switch(
                            value: _hasReminder,
                            activeColor: const Color(0xFF333333),
                            onChanged: (value) {
                              setState(() => _hasReminder = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF333333), // Changé en noir/sombre pour correspondre au thème épuré
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Enregistrer les modifications",
                                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}