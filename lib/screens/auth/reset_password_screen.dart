import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Langue par défaut (peut être synchronisée avec ton app)
  String _currentLanguage = "Français";

  // Dictionnaire des traductions
  final Map<String, Map<String, String>> _localizedTexts = {
    "Français": {
      "title": "Mot de passe oublié",
      "subtitle": "Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.",
      "email_label": "Adresse e-mail",
      "email_empty": "Veuillez entrer votre e-mail",
      "email_invalid": "Veuillez entrer un e-mail valide",
      "btn_send": "Envoyer le lien",
      "success": "Un e-mail de réinitialisation a été envoyé !",
      "back_to_login": "Retour à la connexion",
    },
    "Anglais": {
      "title": "Forgot Password",
      "subtitle": "Enter your email address to receive a reset link.",
      "email_label": "Email Address",
      "email_empty": "Please enter your email",
      "email_invalid": "Please enter a valid email",
      "btn_send": "Send Link",
      "success": "A password reset email has been sent!",
      "back_to_login": "Back to Login",
    },
    "Espagnol": {
      "title": "Contraseña olvidada",
      "subtitle": "Introduzca su correo electrónico para recibir un enlace de restablecimiento.",
      "email_label": "Correo electrónico",
      "email_empty": "Por favor, introduzca su correo",
      "email_invalid": "Por favor, introduzca un correo válido",
      "btn_send": "Enviar enlace",
      "success": "¡Se ha enviado un correo de restablecimiento!",
      "back_to_login": "Volver al inicio de sesión",
    }
  };

  String _t(String key) {
    return _localizedTexts[_currentLanguage]?[key] ?? key;
  }

  // Fonction pour envoyer l'email de réinitialisation Firebase
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t("success")),
            backgroundColor: Colors.green,
          ),
        );
        // Retour automatique à l'écran de connexion après 2 secondes
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? "Erreur";
      if (e.code == 'user-not-found') {
        errorMessage = _currentLanguage == "Français" 
            ? "Aucun utilisateur trouvé avec cet e-mail." 
            : "No user found with this email.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // --- TITRE ---
                Text(
                  _t("title"),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 12),
                // --- SOUS-TITRE ---
                Text(
                  _t("subtitle"),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 40),

                // --- CHAMP EMAIL ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: _t("email_label"),
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _t("email_empty");
                    }
                    // Expression régulière simple pour validation e-mail
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value.trim())) {
                      return _t("email_invalid");
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // --- BOUTON D'ACTION ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _t("btn_send"),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- LIEN DE RETOUR ---
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      _t("back_to_login"),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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