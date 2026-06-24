import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureText = true;

  // Connexion Classique
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de la connexion. Vérifiez vos identifiants.")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- MÉTHODE CONNEXION / INSCRIPTION DIRECTE GOOGLE ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Ajouter la logique avec le package 'google_sign_in' ici
      // Une fois configuré, Firebase gère automatiquement l'inscription si le compte n'existe pas.
      
      // Simulation d'une redirection réussie après configuration :
      // if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action Google activée ! En attente de la configuration de GoogleSignIn.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'authentification Google : $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MÉTHODE CONNEXION / INSCRIPTION DIRECTE FACEBOOK ---
  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Ajouter la logique avec le package 'flutter_facebook_auth' ici
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action Facebook activée ! En attente de la configuration de FacebookAuth.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'authentification Facebook : $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 244, 244),
      body: SafeArea(
        child: _isLoading 
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
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Bienvenue dans votre espace de gestion de tâches !",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Connectez-vous à votre compte ?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 40),

                    // Champ Email
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
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                        ),
                      ),
                      validator: (value) => value!.trim().isEmpty ? "Vérifiez votre email !" : null,
                    ),
                    const SizedBox(height: 20),

                    // Champ Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        hintText: "Mot de passe",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black54),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? "Vérifiez votre mot de passe !" : null,
                    ),
                    
                    // Mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reset-password');
                        }, 
                        child: const Text(
                          "Mot de passe oublié ?",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton Se connecter
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 10, 248, 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Se connecter",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Séparateur "ou continuer avec"
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("ou continuer avec", style: TextStyle(color: Color.fromARGB(255, 17, 17, 17), fontSize: 14)),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- BOUTONS RÉSEAUX SOCIAUX AVEC LOGOS OFFICIELS ET CLIQUABLES ---
                    Row(
                      children: [
                        // Bouton Google
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                              height: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bouton Facebook
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _signInWithFacebook,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/24px-Facebook_Logo_%282019%29.png',
                              height: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Lien Inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas encore de compte ? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: const Text("S'inscrire", style: TextStyle(color: Color.fromARGB(255, 4, 47, 240), fontWeight: FontWeight.bold)),
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