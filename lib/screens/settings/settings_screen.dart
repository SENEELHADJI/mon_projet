import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Variables d'état pour piloter les boutons Switch (interrupteurs)
  bool _isDarkMode = false;
  bool _enableNotifications = true;
  bool _taskReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BOUTON RETOUR ÉPURÉ ---
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              // --- TITRE PRINCIPAL ---
              const Text(
                "Paramètres",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // ================= SECTION : GÉNÉRAL =================
              _buildSectionTitle("Général"),
              const SizedBox(height: 8),
              Container(
                decoration: _buildBoxDecoration(),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      title: const Text("Mode sombre", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: _isDarkMode,
                        activeColor: const Color(0xFF333333),
                        onChanged: (value) {
                          setState(() => _isDarkMode = value);
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text("Langue", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text("Français", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 14),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ================= SECTION : NOTIFICATIONS =================
              _buildSectionTitle("Notifications"),
              const SizedBox(height: 8),
              Container(
                decoration: _buildBoxDecoration(),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      title: const Text("Activer les notifications", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: _enableNotifications,
                        activeColor: const Color(0xFF333333),
                        onChanged: (value) {
                          setState(() => _enableNotifications = value);
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      title: const Text("Rappels de tâches", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: _taskReminders,
                        activeColor: const Color(0xFF333333),
                        onChanged: (value) {
                          setState(() => _taskReminders = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ================= SECTION : AUTRES =================
              _buildSectionTitle("Autres"),
              const SizedBox(height: 8),
              Container(
                decoration: _buildBoxDecoration(),
                child: Column(
                  children: [
                    _buildNavigationTile("À propos de l'application", () {}),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    _buildNavigationTile("Confidentialité", () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // En-tête de catégorie
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  // Décoration réutilisable pour les blocs de paramètres (Coins arrondis 16 et bordure grise fine)
  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  // Élément de liste standard avec une flèche de navigation vers la droite
  Widget _buildNavigationTile(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 14),
      onTap: onTap,
    );
  }
}