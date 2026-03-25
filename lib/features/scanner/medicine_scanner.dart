import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';
import '../dashboard/widgets/glass_card.dart';

class MedicineScanner extends StatefulWidget {
  const MedicineScanner({super.key});

  @override
  State<MedicineScanner> createState() => _MedicineScannerState();
}

class _MedicineScannerState extends State<MedicineScanner>
    with SingleTickerProviderStateMixin {
  Uint8List? imageBytes;
  String extractedText = "";
  String aiExplanation = "";
  bool isLoading = false;
  bool showManualInput = true;
  String selectedScanSource = "gallery";

  final TextEditingController medicineNameController = TextEditingController();
  final picker = ImagePicker();
  final aiService = AIService();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    showManualInput = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    medicineNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    await _pickImageFromSource(kIsWeb ? ImageSource.gallery : ImageSource.camera);
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      imageBytes = bytes;
      showManualInput = false;
      selectedScanSource = source == ImageSource.camera ? "camera" : "gallery";
      extractedText = "Scanning medicine...";
      aiExplanation = "";
      isLoading = true;
    });

    try {
      // Send image bytes directly to AI for medicine identification
      final explanation = await aiService.getMedicineInfoFromImage(bytes);
      setState(() {
        aiExplanation = explanation;
        extractedText = "Scan complete";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        extractedText = "Error scanning medicine.";
        aiExplanation = "❌ Error processing image. Please use the Search tab instead.\n\n💡 Tips:\n• Ensure good lighting\n• Keep the camera steady\n• Focus on the text area";
        isLoading = false;
      });
    }
  }

  Future<void> lookupMedicine() async {
    final medicineName = medicineNameController.text.trim();
    if (medicineName.isEmpty) return;

    setState(() {
      isLoading = true;
      extractedText = "Searching for: $medicineName...";
      aiExplanation = "";
      imageBytes = null;
    });

    try {
      final explanation = await aiService.getMedicineInfo(medicineName);
      setState(() {
        aiExplanation = explanation;
        isLoading = false;
        extractedText = "Medicine Information";
      });
    } catch (e) {
      setState(() {
        aiExplanation = "❌ Error looking up medicine. Please try again.\n\nError: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 700.0 : double.infinity),
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildTabSelector(),
                    if (kIsWeb) _buildWebInfoBanner(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (!showManualInput) _buildScanModeUI(),
                            if (showManualInput) _buildSearchModeUI(),
                            const SizedBox(height: 16),
                            if (isLoading) _buildLoadingCard(),
                            if (!isLoading && aiExplanation.isNotEmpty) _buildResultCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medicine Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Identify medicines and get detailed information',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.lightBlue, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "You can upload a medicine photo on web or search by medicine name below.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton("Scan", Icons.camera_alt, !showManualInput, () => setState(() => showManualInput = false))),
          Expanded(child: _tabButton("Search", Icons.search, showManualInput, () => setState(() => showManualInput = true))),
        ],
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF0099FF)]) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanModeUI() {
    return Column(
      children: [
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: const [
              Icon(Icons.medical_services, color: Colors.cyan, size: 52),
              SizedBox(height: 12),
              Text("How to Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              Text(
                "1. Upload or capture a clear medicine photo\n2. Ensure text is readable\n3. Our AI will identify the medicine and explain its use",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 480;
            final uploadButton = _buildScanActionButton(
              label: "Upload Photo",
              icon: Icons.upload_file,
              filled: true,
              onTap: isLoading
                  ? null
                  : () => _pickImageFromSource(ImageSource.gallery),
            );
            final cameraButton = _buildScanActionButton(
              label: "Use Camera",
              icon: Icons.camera_alt,
              filled: false,
              onTap: isLoading
                  ? null
                  : () => _pickImageFromSource(ImageSource.camera),
            );

            return stacked
                ? Column(
                    children: [
                      SizedBox(width: double.infinity, child: uploadButton),
                      if (!kIsWeb) const SizedBox(height: 12),
                      if (!kIsWeb)
                        SizedBox(width: double.infinity, child: cameraButton),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: uploadButton),
                      if (!kIsWeb) const SizedBox(width: 12),
                      if (!kIsWeb) Expanded(child: cameraButton),
                    ],
                  );
          },
        ),
        if (imageBytes != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                "Source: ${selectedScanSource == "camera" ? "Camera capture" : "Uploaded photo"}",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        if (imageBytes != null) ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.5), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => _pickImageFromSource(ImageSource.gallery),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try another photo"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScanActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                  )
                : null,
            color: filled ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: filled ? null : Border.all(color: Colors.white24),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchModeUI() {
    return Column(
      children: [
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: const [
              Icon(Icons.medication, color: Colors.cyan, size: 44),
              SizedBox(height: 8),
              Text("Search Medicine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 6),
              Text(
                "Enter the medicine name to get detailed information about uses, dosage, and side effects.",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: TextField(
            controller: medicineNameController,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: const InputDecoration(
              hintText: "Enter medicine name (e.g., Paracetamol, Amoxicillin)...",
              hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
              prefixIcon: Icon(Icons.medication, color: Colors.cyan),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSubmitted: (_) => lookupMedicine(),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: lookupMedicine,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF0099FF)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF00D9FF).withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text("Get Medicine Information", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text("Popular Medicines", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ["Paracetamol", "Ibuprofen", "Amoxicillin", "Vitamin C", "Aspirin", "Omeprazole"]
              .map(_buildQuickChip)
              .toList(),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Advanced help: try brand names, generic names, or upload a blister-pack photo for AI-based identification.",
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.cyan),
          const SizedBox(height: 12),
          Text(
            extractedText.isNotEmpty ? extractedText : "Analyzing medicine information...",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 8),
              const Text("Medicine Information",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Text(aiExplanation,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.7)),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String medicine) {
    return GestureDetector(
      onTap: () {
        medicineNameController.text = medicine;
        lookupMedicine();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
        ),
        child: Text(medicine, style: const TextStyle(color: Colors.cyan, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
