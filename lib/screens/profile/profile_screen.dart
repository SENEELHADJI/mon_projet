import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "User Name";
  String _userEmail = "user@email.com";
  String? _userImageUrl; 
  bool _isLoading = true;

  // Langue par défaut
  String _currentLanguage = "Français";

  // Dictionnaire de traductions simples pour l'interface
  final Map<String, Map<String, String>> _localizedTexts = {
    "Français": {
      "title_edit": "Modifier le profil",
      "settings": "Paramètres",
      "language": "Langue",
      "about": "À propos de l'application",
      "logout": "Déconnexion",
      "nav_home": "Accueil",
      "nav_search": "Recherche",
      "nav_add": "Ajouter",
      "nav_notif": "Notifications",
      "nav_profile": "Profil",
      "select_lang": "Choisir la langue",
    },
    "Anglais": {
      "title_edit": "Edit Profile",
      "settings": "Settings",
      "language": "Language",
      "about": "About Application",
      "logout": "Logout",
      "nav_home": "Home",
      "nav_search": "Search",
      "nav_add": "Add",
      "nav_notif": "Notifications",
      "nav_profile": "Profile",
      "select_lang": "Choose Language",
    },
    "Espagnol": {
      "title_edit": "Editar perfil",
      "settings": "Ajustes",
      "language": "Idioma",
      "about": "Acerca de la aplicación",
      "logout": "Cerrar sesión",
      "nav_home": "Inicio",
      "nav_search": "Buscar",
      "nav_add": "Añadir",
      "nav_notif": "Notificaciones",
      "nav_profile": "Perfil",
      "select_lang": "Elegir idioma",
    }
  };

  // Récupérer le texte traduit selon la langue active
  String _t(String key) {
    return _localizedTexts[_currentLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? "user@email.com";
        _userImageUrl = user.photoURL; 
      });

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _userName = doc.data()!['name'] ?? "User Name";
            if (doc.data()!['imageUrl'] != null) {
              _userImageUrl = doc.data()!['imageUrl'];
            }
            // Optionnel : charger la langue sauvegardée de l'utilisateur si elle existe dans Firestore
            if (doc.data()!['language'] != null) {
              _currentLanguage = doc.data()!['language'];
            }
          });
        }
      } catch (e) {
        if (user.displayName != null) {
          setState(() => _userName = user.displayName!);
        }
      }
    }
    setState(() => _isLoading = false);
  }

  // Boîte de dialogue pour changer la langue
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(_t("select_lang"), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Français"),
                trailing: _currentLanguage == "Français" ? const Icon(Icons.check, color: Colors.black) : null,
                onTap: () => _updateLanguage("Français"),
              ),
              ListTile(
                title: const Text("English (Anglais)"),
                trailing: _currentLanguage == "Anglais" ? const Icon(Icons.check, color: Colors.black) : null,
                onTap: () => _updateLanguage("Anglais"),
              ),
              ListTile(
                title: const Text("Español (Espagnol)"),
                trailing: _currentLanguage == "Espagnol" ? const Icon(Icons.check, color: Colors.black) : null,
                onTap: () => _updateLanguage("Espagnol"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Mettre à jour la langue localement et sur Firestore
  Future<void> _updateLanguage(String newLang) async {
    Navigator.pop(context);
    setState(() {
      _currentLanguage = newLang;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'language': newLang,
        }, SetOptions(merge: true));
      } catch (e) {
        // Erreur silencieuse ou log
      }
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    final TextEditingController imageController = TextEditingController(text: _userImageUrl ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(_t("title_edit"), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nom d'utilisateur",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: "URL de l'image de profil",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  setState(() => _isLoading = true);
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'name': nameController.text.trim(),
                      'imageUrl': imageController.text.trim(),
                    }, SetOptions(merge: true));

                    await user.updateDisplayName(nameController.text.trim());
                    if (imageController.text.trim().isNotEmpty) {
                      await user.updatePhotoURL(imageController.text.trim());
                    }

                    setState(() {
                      _userName = nameController.text.trim();
                      _userImageUrl = imageController.text.trim().isNotEmpty ? imageController.text.trim() : null;
                    });

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    // Gestion erreur
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
              child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF333333)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.black, size: 24),
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: _showEditProfileDialog, 
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE2E8F0),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                            image: _userImageUrl != null && _userImageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_userImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _userImageUrl == null || _userImageUrl!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Color(0xFF94A3B8),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF333333),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: _t("title_edit"),
                          onTap: _showEditProfileDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: _t("settings"),
                          showTrailing: true,
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildMenuItem(
                          icon: Icons.language_outlined,
                          title: _t("language"),
                          trailingText: _currentLanguage,
                          showTrailing: true,
                          onTap: _showLanguageDialog, // Ouvre la sélection des 3 langues
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: _t("about"),
                          showTrailing: true,
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: "TaskFlow",
                              applicationVersion: "1.0.0",
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: _t("logout"),
                          textColor: Colors.black,
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 4, 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: _t("nav_home")),
          BottomNavigationBarItem(icon: const Icon(Icons.search), label: _t("nav_search")),
          BottomNavigationBarItem(icon: const Icon(Icons.add_box_outlined), label: _t("nav_add")),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_none_outlined), label: _t("nav_notif")),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: _t("nav_profile")),
        ],
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/dashboard');
          if (index == 1) Navigator.pushReplacementNamed(context, '/search');
          if (index == 2) Navigator.pushNamed(context, '/add-task');
          if (index == 3) Navigator.pushReplacementNamed(context, '/notifications');
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
    bool showTrailing = false,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          if (showTrailing) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 14),
          ]
        ],
      ),
      onTap: onTap,
    );
  }
}