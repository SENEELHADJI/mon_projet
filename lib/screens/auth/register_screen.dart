import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePwd = true;
  bool _obscureConfirmPwd = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Les mots de passe ne correspondent pas.")),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Sauvegarde du nom de l'utilisateur sur Firestore
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'inscription.")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 194, 191, 191),
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Créer un compte",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Remplissez les informations ci-dessous",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 12, 12, 12)),
                ),
                const SizedBox(height: 40),

                // Nom complet
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Nom complet",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color.fromARGB(255, 77, 76, 76)),
                    ),
                  ),
                  validator: (value) => value!.trim().isEmpty ? "Entrez votre nom" : null,
                ),
                const SizedBox(height: 16),

                // Adresse email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Adresse email",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color.fromARGB(255, 248, 4, 4)),
                    ),
                  ),
                  validator: (value) => value!.trim().isEmpty ? "Entrez votre email" : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePwd,
                  decoration: InputDecoration(
                    hintText: "Mot de passe",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black54),
                      onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                    ),
                  ),
                  validator: (value) => value!.length < 6 ? "Minimum 6 caractères" : null,
                ),
                const SizedBox(height: 16),

                // Confirmer le mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPwd,
                  decoration: InputDecoration(
                    hintText: "Confirmer le mot de passe",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPwd ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black54),
                      onPressed: () => setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Confirmez votre mot de passe" : null,
                ),
                const SizedBox(height: 40),

                // Bouton S'inscrire
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "S'inscrire",
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 40),

                // Lien Connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: const Text("Se connecter", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}