import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/ai_service.dart';
import '../../core/constants/colors.dart';
import '../dashboard/widgets/glass_card.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> with SingleTickerProviderStateMixin {
  File? image;
  String extractedText = "";
  String result = "";
  bool isLoading = false;
  bool showManualInput = false;
  
  final TextEditingController medicineNameController = TextEditingController();
  final picker = ImagePicker();
  final aiService = AIService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    medicineNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    image = File(picked.path);
    setState(() {
      showManualInput = false;
    });

    await processImage();
  }

  Future<void> processImage() async {
    if (image == null) return;

    setState(() {
      isLoading = true;
      result = "";
    });

    try {
      final inputImage = InputImage.fromFile(image!);
      final textRecognizer = TextRecognizer();

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      extractedText = recognizedText.text;

      if (extractedText.isEmpty || !isLikelyMedicineText(extractedText)) {
        setState(() {
          result = "❌ No medicine information detected. Please scan a medicine package or strip with visible text.\n\n⚠️ **Disclaimer**: This scanner is designed specifically for medicine packaging. Please ensure you are scanning a legitimate medicine package with readable text.";
          isLoading = false;
        });
        await textRecognizer.close();
        return;
      }

      final aiResponse = await aiService.getMedicineInfo(extractedText);

      setState(() {
        result = aiResponse;
        isLoading = false;
      });

      await textRecognizer.close();
    } catch (e) {
      setState(() {
        result = "❌ Error processing image. Please try again with a clear photo of medicine packaging.\n\n💡 Tips:\n• Ensure good lighting\n• Keep the camera steady\n• Focus on the text area\n• Avoid blurry images";
        isLoading = false;
      });
    }
  }

  Future<void> lookupMedicine() async {
    String medicineName = medicineNameController.text.trim();
    if (medicineName.isEmpty) return;

    setState(() {
      isLoading = true;
      result = "";
      image = null;
    });

    try {
      final aiResponse = await aiService.getMedicineInfo(medicineName);
      setState(() {
        result = aiResponse;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = "❌ Error looking up medicine. Please try again.\n\nError: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  bool isLikelyMedicineText(String text) {
    if (text.isEmpty) return false;
    
    String lowerText = text.toLowerCase();
    
    List<String> medicineKeywords = [
      'mg', 'ml', 'tablet', 'capsule', 'syrup', 'ointment', 'cream', 'gel',
      'paracetamol', 'ibuprofen', 'amoxicillin', 'aspirin', 'vitamin',
      'active', 'ingredients', 'composition', 'dosage', 'usage', 'side', 'effects',
      'manufacturer', 'expiry', 'batch', 'mfg', 'exp', 'use', 'before',
      'contents', 'directions', 'warning', 'caution', 'prescription', 'rx',
      'drug', 'medicine', 'pill', 'dose', 'taken', 'daily', 'twice', 'thrice'
    ];

    int keywordCount = 0;
    for (String keyword in medicineKeywords) {
      if (lowerText.contains(keyword)) {
        keywordCount++;
      }
    }

    return keywordCount >= 2;
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
                            'Medicine Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.055,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Identify medicines and get detailed information',
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
              
              // Tab Selector
              Container(
                margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                padding: EdgeInsets.all(width * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => showManualInput = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: width * 0.03),
                          decoration: BoxDecoration(
                            gradient: !showManualInput 
                              ? const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF0099FF)])
                              : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: width * 0.05,
                              ),
                              SizedBox(width: width * 0.02),
                              Text(
                                'Scan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.04,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => showManualInput = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: width * 0.03),
                          decoration: BoxDecoration(
                            gradient: showManualInput 
                              ? const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF0099FF)])
                              : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.white,
                                size: width * 0.05,
                              ),
                              SizedBox(width: width * 0.02),
                              Text(
                                'Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.04,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: width * 0.04),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: Column(
                    children: [
                      if (!showManualInput) ...[
                        // Scan Mode UI
                        GlassCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: Colors.cyan,
                                size: width * 0.15,
                              ),
                              SizedBox(height: width * 0.03),
                              Text(
                                "How to Scan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.05,
                                ),
                              ),
                              SizedBox(height: width * 0.02),
                              Text(
                                "1. Take a clear photo of medicine packaging\n2. Ensure text is readable\n3. Avoid scanning non-medicine items",
                                style: TextStyle(
                                  color: Colors.white70, 
                                  fontSize: width * 0.035,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: width * 0.04),
                        
                        // Scan Button
                        GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            padding: EdgeInsets.all(width * 0.05),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D9FF).withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white, size: width * 0.07),
                                SizedBox(width: width * 0.03),
                                Text(
                                  "Scan Medicine Package",
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
                        
                        // Image Preview
                        if (image != null)
                          Container(
                            height: width * 0.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                image!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ] else ...[
                        // Search Mode UI
                        GlassCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.medication,
                                color: Colors.cyan,
                                size: width * 0.12,
                              ),
                              SizedBox(height: width * 0.02),
                              Text(
                                "Search Medicine",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.045,
                                ),
                              ),
                              SizedBox(height: width * 0.015),
                              Text(
                                "Enter the medicine name to get detailed information about its uses, dosage, and side effects.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.032,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: width * 0.04),
                        
                        // Search Input
                        Container(
                          padding: EdgeInsets.all(width * 0.01),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: medicineNameController,
                            style: TextStyle(color: Colors.black87, fontSize: width * 0.04),
                            decoration: InputDecoration(
                              hintText: "Enter medicine name (e.g., Paracetamol, Amoxicillin)...",
                              hintStyle: TextStyle(color: Colors.black45, fontSize: width * 0.035),
                              prefixIcon: Icon(Icons.medication, color: Colors.cyan, size: width * 0.06),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: width * 0.04,
                              ),
                            ),
                            onSubmitted: (value) => lookupMedicine(),
                          ),
                        ),
                        
                        SizedBox(height: width * 0.04),
                        
                        // Search Button
                        GestureDetector(
                          onTap: lookupMedicine,
                          child: Container(
                            padding: EdgeInsets.all(width * 0.04),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D9FF).withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white, size: width * 0.06),
                                SizedBox(width: width * 0.02),
                                Text(
                                  "Get Medicine Information",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: width * 0.04),
                        
                        // Popular Medicines Quick Search
                        Text(
                          "Popular Medicines",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                          ),
                        ),
                        
                        SizedBox(height: width * 0.03),
                        
                        Wrap(
                          spacing: width * 0.02,
                          runSpacing: width * 0.02,
                          children: [
                            _buildQuickSearchChip("Paracetamol"),
                            _buildQuickSearchChip("Ibuprofen"),
                            _buildQuickSearchChip("Amoxicillin"),
                            _buildQuickSearchChip("Vitamin C"),
                            _buildQuickSearchChip("Aspirin"),
                            _buildQuickSearchChip("Omeprazole"),
                          ],
                        ),
                      ],
                      
                      SizedBox(height: width * 0.04),
                      
                      // Loading Indicator
                      if (isLoading)
                        Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: Colors.cyan),
                              SizedBox(height: width * 0.03),
                              Text(
                                "Analyzing medicine information...",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.035,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Results
                      if (!isLoading && result.isNotEmpty)
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
                            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.1),
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
                                    "Medicine Information",
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

  Widget _buildQuickSearchChip(String medicine) {
    double chipWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        medicineNameController.text = medicine;
        lookupMedicine();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: chipWidth * 0.04,
          vertical: chipWidth * 0.025,
        ),
        decoration: BoxDecoration(
          color: Colors.cyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withOpacity(0.5)),
        ),
        child: Text(
          medicine,
          style: TextStyle(
            color: Colors.cyan,
            fontSize: chipWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
