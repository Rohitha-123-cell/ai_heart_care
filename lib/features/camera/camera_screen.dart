import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';
import '../dashboard/widgets/glass_card.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  File? image;
  String result = "";
  bool isLoading = false;
  final picker = ImagePicker();
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      image = File(picked.path);
      result = "";
      isLoading = true;
    });

    final aiService = AIService();
    final response = await aiService.analyzeImage(image!);

    setState(() {
      result = response;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.all(width * 0.04),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(width * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: width * 0.06),
                      ),
                    ),
                    SizedBox(width: width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skin Detection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'AI-powered skin analysis',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.03,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      // Info Card
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withOpacity(0.2),
                              Colors.deepPurple.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(width * 0.03),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(Icons.face_retouching_natural, color: Colors.purple, size: width * 0.08),
                            ),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Skin Analysis",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.04,
                                    ),
                                  ),
                                  SizedBox(height: width * 0.01),
                                  Text(
                                    "Capture an image to detect skin conditions",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: width * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: width * 0.05),

                      // Preview Area
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: image == null ? _pulseAnimation.value : 1.0,
                            child: Container(
                              height: width * 0.7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.5),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: image != null
                                    ? Image.file(image!, fit: BoxFit.cover)
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.withOpacity(0.1),
                                              Colors.deepPurple.withOpacity(0.1),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(width * 0.04),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                size: width * 0.15,
                                                color: Colors.purple,
                                              ),
                                            ),
                                            SizedBox(height: width * 0.04),
                                            Text(
                                              "Tap to Capture",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: width * 0.04,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: width * 0.02),
                                            Text(
                                              "Position the affected area in frame",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: width * 0.03,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: width * 0.05),

                      // Capture Button
                      GestureDetector(
                        onTap: isLoading ? null : pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(width * 0.045),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera, color: Colors.white, size: width * 0.06),
                              SizedBox(width: width * 0.02),
                              Text(
                                image == null ? "Capture Image" : "Capture Another",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.045,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: width * 0.04),

                      // Tips
                      Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber, size: width * 0.05),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: Text(
                                "Ensure good lighting for accurate analysis",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.03,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: width * 0.04),

                      // Loading
                      if (isLoading)
                        Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: Colors.purple),
                              SizedBox(height: width * 0.03),
                              Text(
                                "Analyzing skin...",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.035,
                                ),
                              ),
                              SizedBox(height: width * 0.01),
                              Text(
                                "Our AI is examining the image",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: width * 0.028,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Result
                      if (result.isNotEmpty && !isLoading)
                        Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(width * 0.02),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.check_circle, color: Colors.green, size: width * 0.06),
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    "Analysis Result",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.045,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: width * 0.03),
                              const Divider(color: Colors.white24),
                              SizedBox(height: width * 0.03),
                              Text(
                                result,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.035,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: width * 0.04),

                      // Disclaimer
                      Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.amber, size: width * 0.05),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: Text(
                                "⚠️ This is AI-generated analysis and should not replace professional dermatological advice.",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: width * 0.028,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: width * 0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
