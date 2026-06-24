import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchScreen extends StatefulWidget {
  // Le mot-clé "const" ici est indispensable pour l'utiliser avec "const SearchScreen()" dans les routes !
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'haute':
        return const Color(0xFFE2E8F0);
      case 'moyenne':
        return const Color(0xFFEDF2F7);
      case 'faible':
        return const Color(0xFFF7FAFC);
      default:
        return const Color(0xFFEDF2F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              const Text(
                "Recherche",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Rechercher une tâche...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                  suffixIcon: const Icon(Icons.search, color: Colors.black, size: 22),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF333333), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Résultats",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: userId == null
                    ? const Center(child: Text("Utilisateur non connecté"))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tasks')
                            .where('userId', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text("Aucune tâche trouvée", style: TextStyle(color: Colors.grey)),
                            );
                          }

                          final docs = snapshot.data!.docs.where((doc) {
                            final taskData = doc.data() as Map<String, dynamic>;
                            final title = (taskData['title'] ?? '').toString().toLowerCase();
                            final desc = (taskData['description'] ?? '').toString().toLowerCase();
                            return title.contains(_searchQuery) || desc.contains(_searchQuery);
                          }).toList();

                          if (docs.isEmpty) {
                            return const Center(
                              child: Text("Aucun résultat correspondant", style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final taskDoc = docs[index];
                              final task = taskDoc.data() as Map<String, dynamic>;
                              
                              final String title = task['title'] ?? 'Sans titre';
                              final bool isDone = task['isDone'] ?? false;
                              final String priority = task['priority'] ?? 'Moyenne'; 
                              final String dateText = task['dueDate'] ?? 'Aujourd\'hui, 20:00'; 

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFA0AEC0), width: 1.5),
                                    ),
                                    child: isDone
                                        ? const Icon(Icons.check, size: 14, color: Color(0xFF333333))
                                        : null,
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      dateText,
                                      style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(priority),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      priority,
                                      style: const TextStyle(color: Color(0xFF4A5568), fontWeight: FontWeight.w500, fontSize: 12),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/task-details',
                                      arguments: taskDoc.id,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}