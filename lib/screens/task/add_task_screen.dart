import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  bool _isLoading = false;

  DateTime? _selectedDate;
  String _selectedPriority = 'Moyenne'; 
  bool _isReminderEnabled = false;

  // Calendrier avec le style de ton application
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF333333), 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- CORRECTION DE LA MÉTHODE D'ENREGISTREMENT ---
  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception("Aucun utilisateur connecté");
      }

      // Pour éviter les bugs de filtrage sur ton Dashboard, on harmonise la date.
      // Si aucune date n'est choisie, on attribue la date actuelle (Aujourd'hui).
      final DateTime finalDate = _selectedDate ?? DateTime.now();

      // Création du document avec une référence Firestore
      final taskRef = FirebaseFirestore.instance.collection('tasks').doc();

      // On utilise set() avec un Timeout ou une exécution asynchrone fluide
      await taskRef.set({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'isDone': false,
        'userId': user.uid,
        // Correction : On stocke un vrai Timestamp pour que ton Dashboard l'analyse sans crasher
        'date': Timestamp.fromDate(finalDate), 
        'dueDate': "${finalDate.day}/${finalDate.month}/${finalDate.year}", 
        'priority': _selectedPriority,        
        'hasReminder': _isReminderEnabled,    
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Ferme l'écran immédiatement après l'appel réussi
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // En cas de problème de connexion ou de règles Firebase, on avertit clairement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'enregistrement : ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      backgroundColor: const Color(0xFFF8F9FA), // Fond ultra-clair harmonisé avec le Dashboard
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF333333), size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Nouvelle tâche",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ajoutez les détails de votre objectif ci-dessous.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 40),

                // Champ Titre
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Titre de la tâche",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.assignment_outlined, color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF333333), width: 1.5),
                    ),
                  ),
                  validator: (value) => value!.trim().isEmpty ? "Le titre ne peut pas être vide" : null,
                ),
                const SizedBox(height: 20),

                // Champ Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Description / Notes (Optionnel)",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60.0), 
                      child: Icon(Icons.description_outlined, color: Colors.black54),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF333333), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Zone de sélection de la Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Date",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedDate == null 
                                  ? "Sélectionner une date" 
                                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                              style: TextStyle(
                                color: _selectedDate == null ? Colors.grey : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Zone de sélection de la Priorité
                const Text(
                  "Priorité",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Faible', 'Moyenne', 'Haute'].map((priority) {
                    return InkWell(
                      onTap: () => setState(() => _selectedPriority = priority),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: priority,
                            groupValue: _selectedPriority,
                            activeColor: const Color(0xFF333333),
                            onChanged: (value) {
                              setState(() => _selectedPriority = value!);
                            },
                          ),
                          Text(
                            priority,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Zone Rappel
                const Text(
                  "Rappel",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Activer le rappel",
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    Switch(
                      value: _isReminderEnabled,
                      activeColor: const Color(0xFF333333),
                      onChanged: (value) {
                        setState(() => _isReminderEnabled = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bouton Enregistrer épuré (Noir/Gris Foncé conforme à ta charte graphique)
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            "Enregistrer",
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