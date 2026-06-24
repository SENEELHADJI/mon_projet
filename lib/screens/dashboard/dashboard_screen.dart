import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String _selectedPriorityFilter = 'Toutes';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  int _currentIndex = 0; 

  void _onBottomTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/search');
        break;
      case 2:
        Navigator.pushNamed(context, '/add-task');
        break;
      case 3:
        Navigator.pushNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  String _formatTaskDateTime(dynamic timestamp) {
    if (timestamp == null) return "Pas de date";
    DateTime dateTime;
    
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      if (timestamp.contains('/')) {
        try {
          List<String> parts = timestamp.split(' ')[0].split('/');
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          dateTime = DateTime(year, month, day);
        } catch (_) {
          dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
        }
      } else {
        dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
      }
    } else {
      return "Pas de date";
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayString;
    if (taskDay == today) {
      dayString = "Aujourd'hui";
    } else if (taskDay == tomorrow) {
      dayString = "Demain";
    } else {
      dayString = DateFormat('d MMMM yyyy', 'fr_FR').format(dateTime);
    }

    final timeString = DateFormat('HH:mm').format(dateTime);
    return "$dayString, $timeString";
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'haute':
        return const Color(0xFF4CAF50);
      case 'moyenne':
        return const Color(0xFFFF9800);
      case 'faible':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = _user?.displayName ?? _user?.email?.split('@')[0] ?? "Utilisateur";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bonjour, $userName 👋",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, color: Colors.black, size: 28),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                ],
              ),
            ),

            // --- BARRE DE RECHERCHE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "Rechercher une tâche...",
                    hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: Colors.black, size: 22),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // --- FILTRES DE PRIORITÉ (CORRIGÉS AVEC withValues) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton("Toutes", const Color(0xFFE2E8F0), Colors.black),
                    const SizedBox(width: 8),
                    _buildFilterButton("Haute", const Color(0xFF4CAF50).withValues(alpha: 0.1), const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    _buildFilterButton("Moyenne", const Color(0xFFFF9800).withValues(alpha: 0.1), const Color(0xFFFF9800)),
                    const SizedBox(width: 8),
                    _buildFilterButton("Faible", const Color(0xFFF44336).withValues(alpha: 0.1), const Color(0xFFF44336)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            
            // --- TEXTE CORRIGÉ (Suppression du const inutile détecté ligne 187) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Mes tâches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),

            const SizedBox(height: 14),

            // --- LISTE DES TÂCHES ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId', isEqualTo: _user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Une erreur est survenue"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
                  }

                  var docs = snapshot.data?.docs ?? [];

                  final tasks = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String priority = data['priority'] ?? 'Faible';
                    String title = (data['title'] ?? '').toString().toLowerCase();

                    bool matchesPriority = _selectedPriorityFilter == 'Toutes' || 
                        priority.toLowerCase() == _selectedPriorityFilter.toLowerCase();
                    bool matchesSearch = title.contains(_searchQuery);

                    return matchesPriority && matchesSearch;
                  }).toList();

                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucune tâche trouvée",
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      var task = tasks[index].data() as Map<String, dynamic>;
                      String taskId = tasks[index].id;
                      bool isDone = task['isDone'] ?? false;
                      String priority = task['priority'] ?? 'Faible';
                      dynamic taskDate = task['date'] ?? task['dueDate'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              activeColor: const Color(0xFF333333),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              value: isDone,
                              onChanged: (bool? value) async {
                                await FirebaseFirestore.instance
                                    .collection('tasks')
                                    .doc(taskId)
                                    .update({'isDone': value});
                              },
                            ),
                          ),
                          title: Text(
                            task['title'] ?? 'Sans titre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _formatTaskDateTime(taskDate),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context, 
                                '/edit-task', 
                                arguments: taskId,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                // --- CORRECTION ICI AUSSI POUR LE BADGE DE LA LISTE ---
                                color: _getPriorityColor(priority).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(
                                  color: _getPriorityColor(priority),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF333333),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Recherche"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded), label: "Ajouter"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, Color activeBgColor, Color textColor) {
    bool isSelected = _selectedPriorityFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriorityFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (label == "Toutes" ? const Color(0xFFCBD5E1) : activeBgColor) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? textColor : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}