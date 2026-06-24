import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_task_screen.dart'; 

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  bool _isInit = false;
  bool _isLoading = false;
  late String _taskId;

  // Variables pour stocker les données de la tâche venant de Firestore
  String _title = '';
  String _description = '';
  String _dueDate = "Aujourd'hui, 10 Mai 2024 à 20:00"; 
  String _priority = 'Moyenne';
  String _reminder = 'Désactivé';
  bool _isDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _taskId = ModalRoute.of(context)!.settings.arguments as String;
      _loadTaskData();
      _isInit = true;
    }
  }

  // Charger ou rafraîchir les données de la tâche depuis Firestore
  Future<void> _loadTaskData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance.collection('tasks').doc(_taskId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _title = data['title'] ?? '';
          _description = data['description'] ?? "Aucune description fournie.";
          _isDone = data['isDone'] ?? false;
          _priority = data['priority'] ?? 'Moyenne';
          
          if (data['dueDate'] != null) {
            _dueDate = data['dueDate'];
          }
          
          if (data['hasReminder'] == true) {
            _reminder = data['reminderTime'] ?? 'Activé';
          } else {
            _reminder = 'Désactivé';
          }
        });
      }
    } catch (e) {
      _showSnackBar("Erreur lors du chargement de la tâche", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Inverser ou marquer le statut "Terminée"
  Future<void> _toggleTaskStatus() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(_taskId).update({
        'isDone': !_isDone,
      });
      setState(() => _isDone = !_isDone);
      _showSnackBar(_isDone ? "Tâche terminée !" : "Tâche réouverte", Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Une erreur est survenue.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Supprimer la tâche
  Future<void> _deleteTask() async {
    bool confirm = await _showDeleteConfirmationDialog() ?? false;
    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('tasks').doc(_taskId).delete();
        _showSnackBar("Tâche supprimée", Colors.orange);
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar("Impossible de supprimer la tâche.", Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer la tâche ?"),
        content: const Text("Cette action est irréversible. Voulez-vous continuer ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Color.fromARGB(255, 26, 25, 25), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 151, 151, 151), 
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF333333)))
            : Column(
                children: [
                  // --- BARRE D'ACTION SUPÉRIEURE (En-tête) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            // 🛠️ LE BOUTON CRAYON CORRIGÉ AVEC ROUTAGE SÉCURISÉ ET RECHARGEMENT D'ÉTAT
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.black, size: 24),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditTaskScreen(),
                                    settings: RouteSettings(arguments: _taskId),
                                  ),
                                );
                                // Quand l'utilisateur revient de EditTaskScreen, on rafraîchit immédiatement l'affichage
                                _loadTaskData();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 243, 2, 2), size: 24),
                              onPressed: _deleteTask,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- ZONE DE CONTENU DÉROULANTE ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // --- ZONE TITRE ET CASE À COCHER ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.3,
                                child: Checkbox(
                                  value: _isDone,
                                  shape: const CircleBorder(),
                                  activeColor: const Color.fromARGB(255, 94, 250, 4),
                                  side: const BorderSide(color: Color.fromARGB(255, 83, 83, 83), width: 1.5),
                                  onChanged: (value) => _toggleTaskStatus(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _title,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 4, 245, 205),
                                    decoration: _isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // --- BADGE DE PRIORITÉ ---
                          Container(
                            margin: const EdgeInsets.only(left: 52.0), 
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 13, 126, 3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _priority,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 📦 BOÎTE DE DÉTAILS DE LA TÂCHE
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                            ),
                            child: Column(
                              children: [
                                _buildDetailItem(
                                  title: "Date",
                                  content: _dueDate,
                                ),
                                const Divider(height: 1, color: Color(0xFFEAEAEA)),
                                _buildDetailItem(
                                  title: "Description",
                                  content: _description,
                                ),
                                const Divider(height: 1, color: Color(0xFFEAEAEA)),
                                _buildDetailItem(
                                  title: "Rappel",
                                  content: _reminder,
                                ),
                                const Divider(height: 1, color: Color(0xFFEAEAEA)),
                                
                                // --- SECTION PARTAGER ---
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Partager",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          _buildShareIcon(Icons.chat_bubble_outline, const Color(0xFF25D366)), 
                                          const SizedBox(width: 16),
                                          _buildShareIcon(Icons.facebook, const Color(0xFF1877F2)),
                                          const SizedBox(width: 16),
                                          _buildShareIcon(Icons.share_outlined, Colors.black54),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // --- BOUTON PRINCIPAL EN BAS ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _toggleTaskStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 245, 99, 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          _isDone ? "Réouvrir la tâche" : "Marquer comme terminée",
                          style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 20, 20, 20), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailItem({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}