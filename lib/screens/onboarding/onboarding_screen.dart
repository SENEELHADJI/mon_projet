import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Organisez vos journées en toute simplicité",
      "desc": "Planifiez vos tâches quotidiennes et restez productif en toute circonstance.",
      "type": "tasks"
    },
    {
      "title": "Suivez vos progrès en un coup d'œil !",
      "desc": "Visualisez vos accomplissements en temps réel grâce à nos graphiques simples.",
      "type": "progress"
    },
    {
      "title": "Ne ratez aucune deadline",
      "desc": "Recevez des rappels intelligentes pour vos tâches prioritaires.",
      "type": "notifications"
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 121, 114, 114),
      body: SafeArea(
        child: Column(
          children: [
            // --- BOUTON PASSER ---
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    "Passer",
                    style: TextStyle(
                      color: Color.fromARGB(255, 2, 245, 75),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            
            // --- CONTENU DÉFILANT CORRIGÉ ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => _buildPageContent(
                  title: _onboardingData[index]["title"]!,
                  desc: _onboardingData[index]["desc"]!,
                  type: _onboardingData[index]["type"]!,
                ),
              ),
            ),

            // --- CONTROLES DU BAS (INDICATEURS & BOUTON ACTION) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Points indicateurs minimalistes
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index: index),
                    ),
                  ),
                  
                  // Bouton Suivant / Commencer (Gris anthracite #333333)
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _navigateToLogin();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 69, 182, 46), 
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), 
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? "Commencer" : "Suivant",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent({required String title, required String desc, required String type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Remplacement des Emojis bruts par des illustrations vectorielles épurées
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: OnboardingIllustrationPainter(type: type),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 250, 249, 249),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// --- ILLUSTRATIONS VECTORIELLES ÉPURÉES (STYLE FILAIRE MAQUETTE) ---
class OnboardingIllustrationPainter extends CustomPainter {
  final String type;
  OnboardingIllustrationPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 109, 240, 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFF1F3F5)
      ..style = PaintingStyle.fill;

    if (type == "tasks") {
      // Dessin d'une liste de tâches minimaliste
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 160, 160), const Radius.circular(24)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 160, 160), const Radius.circular(24)), paint);
      
      // Lignes de tâches
      for (var i = 0; i < 3; i++) {
        double y = 60.0 + (i * 40);
        canvas.drawCircle(Offset(50, y), 8, paint);
        canvas.drawLine(Offset(75, y), Offset(150, y), paint);
      }
    } else if (type == "progress") {
      // Dessin d'un graphique épuré
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 160, 160), const Radius.circular(24)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 160, 160), const Radius.circular(24)), paint);
      
      // Barres de progression
      final barPaint = Paint()..style = PaintingStyle.fill;
      List<double> heights = [60, 100, 70, 120];
      for (var i = 0; i < heights.length; i++) {
        barPaint.color = i == 3 ? const Color.fromARGB(255, 2, 230, 247) : const Color.fromARGB(255, 247, 133, 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(45.0 + (i * 30), 150.0 - heights[i], 18, heights[i]), const Radius.circular(4)),
          barPaint,
        );
      }
    } else if (type == "notifications") {
      // Dessin de l'icône cloche épurée
      canvas.drawCircle(const Offset(100, 100), 75, fillPaint);
      
      final path = Path()
        ..moveTo(100, 45)
        ..cubicTo(75, 45, 70, 85, 70, 115)
        ..lineTo(130, 115)
        ..cubicTo(130, 85, 125, 45, 100, 45)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(const Offset(60, 125), const Offset(140, 125), paint);
      canvas.drawArc(const Rect.fromLTWH(88, 125, 24, 24), 0, 3.14, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}