import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String _currentLanguage = "Français";
  bool _isLangLoading = true;

  // Dictionnaire pour gérer les traductions sur cet écran
  final Map<String, Map<String, String>> _localizedTexts = {
    "Français": {
      "notif_title": "Notifications",
      "no_notif": "Aucune notification pour le moment.",
      "error": "Une erreur est survenue lors du chargement.",
      "nav_home": "Accueil",
      "nav_search": "Recherche",
      "nav_add": "Ajouter",
      "nav_notif": "Notifications",
      "nav_profile": "Profil",
      "reminder_text": "Rappel : Votre tâche arrive à échéance.",
    },
    "Anglais": {
      "notif_title": "Notifications",
      "no_notif": "No notifications at the moment.",
      "error": "An error occurred while loading.",
      "nav_home": "Home",
      "nav_search": "Search",
      "nav_add": "Add",
      "nav_notif": "Notifications",
      "nav_profile": "Profile",
      "reminder_text": "Reminder: Your task is due soon.",
    },
    "Espagnol": {
      "notif_title": "Notificaciones",
      "no_notif": "No hay notificaciones de momento.",
      "error": "Ocurrió un error lors de la carga.",
      "nav_home": "Inicio",
      "nav_search": "Buscar",
      "nav_add": "Añadir",
      "nav_notif": "Notificaciones",
      "nav_profile": "Perfil",
      "reminder_text": "Recordatorio: Tu tarea vence pronto.",
    }
  };

  String _t(String key) {
    return _localizedTexts[_currentLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  // Charge la langue préférée configurée sur le profil de l'utilisateur
  Future<void> _loadUserLanguage() async {
    if (_user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!['language'] != null) {
          setState(() {
            _currentLanguage = doc.data()!['language'];
          });
        }
      } catch (_) {}
    }
    setState(() => _isLangLoading = false);
  }

  // Calcule de manière dynamique le temps écoulé ou restant (Ex: "5 min", "1 h")
  String _calculateTimeAgo(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return "";
    }

    final now = DateTime.now();
    final difference = now.difference(date).abs();

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} h";
    } else {
      return "${difference.inDays} j";
    }
  }

  // Gère la navigation du menu inférieur
  void _onBottomTabTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        Navigator.pushNamed(context, '/add-task');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLangLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF333333)))
            : Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t("notif_title"),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      // --- ECOUTE DYNAMIQUE DES RAPPELS SUR FIRESTORE ---
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tasks')
                            .where('userId', isEqualTo: _user?.uid)
                            .where('hasReminder', isEqualTo: true) // Filtre : uniquement avec rappels activés
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text(_t("error")));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                _t("no_notif"),
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E7EB), height: 32),
                            itemBuilder: (context, index) {
                              var task = docs[index].data() as Map<String, dynamic>;
                              String title = task['title'] ?? 'Sans titre';
                              String description = task['description'] ?? '';
                              dynamic dueDate = task['date'] ?? task['dueDate'];

                              // Si aucune description, on met une phrase de rappel par défaut
                              String displayDesc = description.isNotEmpty 
                                  ? description 
                                  : _t("reminder_text");

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icône enveloppée comme sur la maquette d'origine
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  // Contenu Texte dynamique
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _calculateTimeAgo(dueDate),
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          displayDesc,
                                          style: const TextStyle(color: Color(0xFF555555), fontSize: 14, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
      
      // --- BARRE DE NAVIGATION INFÉRIEURE SYNCHRONISÉE ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Positionné sur l'onglet Notifications (Index 3)
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: _t("nav_home")),
          BottomNavigationBarItem(icon: const Icon(Icons.search), label: _t("nav_search")),
          BottomNavigationBarItem(icon: const Icon(Icons.add_box_outlined), label: _t("nav_add")),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: _t("nav_notif")),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: _t("nav_profile")),
        ],
        onTap: _onBottomTabTapped,
      ),
    );
  }
}