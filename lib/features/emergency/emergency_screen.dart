import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../hospitals/map_screen.dart';
import '../../services/health_data_provider.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> 
    with SingleTickerProviderStateMixin {
  
  bool isEmergency = false;
  int selectedSymptom = -1;
  
  // Custom emergency contact
  String _customContactName = '';
  String _customContactNumber = '';
  bool _isLoadingContact = true;
  
  // India Emergency Contacts
  final List<Map<String, dynamic>> emergencyContacts = [
    {'name': 'Emergency Response', 'number': '112', 'icon': Icons.emergency, 'color': Colors.red, 'subtitle': 'All-in-One Emergency (Police/Ambulance/Fire)'},
    {'name': 'Ambulance', 'number': '108', 'icon': Icons.local_hospital, 'color': Colors.green, 'subtitle': 'Medical Emergency'},
    {'name': 'Police', 'number': '100', 'icon': Icons.local_police, 'color': Colors.blue, 'subtitle': 'Law & Order'},
    {'name': 'Fire', 'number': '101', 'icon': Icons.local_fire_department, 'color': Colors.orange, 'subtitle': 'Fire Emergency'},
    {'name': 'Women Helpline', 'number': '1091', 'icon': Icons.woman, 'color': Colors.pink, 'subtitle': 'Women Safety'},
  ];

  // Critical symptoms
  final List<Map<String, dynamic>> symptoms = [
    {'title': 'Severe Chest Pain', 'subtitle': 'Heart attack or cardiac emergency', 'icon': Icons.favorite, 'color': Colors.red, 'weight': 10},
    {'title': 'Difficulty Breathing', 'subtitle': 'Shortness of breath or suffocation', 'icon': Icons.air, 'color': Colors.blue, 'weight': 10},
    {'title': 'Sudden Weakness', 'subtitle': 'Numbness or paralysis symptoms', 'icon': Icons.accessibility_new, 'color': Colors.purple, 'weight': 10},
    {'title': 'Severe Bleeding', 'subtitle': 'Uncontrolled blood loss', 'icon': Icons.water_drop, 'color': Colors.red, 'weight': 10},
    {'title': 'Loss of Consciousness', 'subtitle': 'Fainting or unconsciousness', 'icon': Icons.visibility_off, 'color': Colors.deepOrange, 'weight': 10},
    {'title': 'Severe Allergic Reaction', 'subtitle': 'Anaphylaxis symptoms', 'icon': Icons.sick, 'color': Colors.pink, 'weight': 8},
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadCustomContact();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCustomContact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _customContactName = prefs.getString('emergency_contact_name') ?? '';
        _customContactNumber = prefs.getString('emergency_contact_number') ?? '';
        _isLoadingContact = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContact = false;
      });
    }
  }

  Future<void> _saveCustomContact(String name, String number) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergency_contact_name', name);
      await prefs.setString('emergency_contact_number', number);
      setState(() {
        _customContactName = name;
        _customContactNumber = number;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save contact'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void triggerEmergency() {
    setState(() {
      isEmergency = true;
    });
    _pulseController.repeat(reverse: true);
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  void cancelEmergency() {
    setState(() {
      isEmergency = false;
      selectedSymptom = -1;
    });
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.reset();
  }

  Future<void> callNumber(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCallConfirmation(String name, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              'Call $name?',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.call, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    number,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              callNumber(number);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController(text: _customContactName);
    final numberController = TextEditingController(text: _customContactNumber);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.contact_phone, color: Colors.cyan, size: 28),
            SizedBox(width: 12),
            Text(
              'Add Emergency Contact',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Save a family member or friend who can be contacted in emergencies.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contact Name',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'e.g., Mom, Dad, Friend',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.person, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'e.g., 9876543210',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && numberController.text.isNotEmpty) {
                _saveCustomContact(nameController.text, numberController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isEmergency
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.red.shade900, Colors.red.shade700, Colors.red.shade500],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                ),
        ),
        child: SafeArea(
          child: isEmergency 
              ? _buildEmergencyActive(width) 
              : _buildEmergencyCheck(width),
        ),
      ),
    );
  }

  Widget _buildEmergencyCheck(double width) {
    return Column(
      children: [
        _buildAppBar(width),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              children: [
                _buildWarningCard(width),
                SizedBox(height: width * 0.04),
                _buildIndiaEmergencyNumbers(width),
                SizedBox(height: width * 0.04),
                _buildCustomContactCard(width),
                SizedBox(height: width * 0.04),
                _buildSymptomsSection(width),
                SizedBox(height: width * 0.04),
                _buildQuickActionsCard(width),
                SizedBox(height: width * 0.04),
                _buildSafetyTipsCard(width),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(double width) {
    return Container(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Emergency Help',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge("🇮🇳 India", Colors.blue),
                    const SizedBox(width: 8),
                    _buildBadge("🚨 24/7", Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildWarningCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: width * 0.08),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Life-Threatening Emergency?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Call 112 or 108 immediately for immediate assistance.",
                  style: TextStyle(color: Colors.red.shade100, fontSize: width * 0.028),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndiaEmergencyNumbers(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                "India Emergency Numbers",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "All services available 24/7 across India",
            style: TextStyle(color: Colors.grey.shade400, fontSize: width * 0.028),
          ),
          SizedBox(height: width * 0.03),
          ...emergencyContacts.map((contact) {
            Color contactColor = contact['color'] as Color;
            return GestureDetector(
              onTap: () => _showCallConfirmation(contact['name'], contact['number']),
              child: Container(
                margin: EdgeInsets.only(bottom: width * 0.02),
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: contactColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: contactColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.02),
                      decoration: BoxDecoration(
                        color: contactColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(contact['icon'], color: contactColor, size: width * 0.06),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'],
                            style: TextStyle(color: Colors.white, fontSize: width * 0.032, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            contact['subtitle'],
                            style: TextStyle(color: Colors.grey.shade400, fontSize: width * 0.024),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: contactColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          contact['number'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.call, color: contactColor, size: width * 0.05),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomContactCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.withOpacity(0.15), Colors.cyan.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_phone, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                "Custom Emergency Contact",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Save a family member or friend for emergencies",
            style: TextStyle(color: Colors.grey.shade400, fontSize: width * 0.028),
          ),
          SizedBox(height: width * 0.03),
          if (_isLoadingContact)
            const Center(child: CircularProgressIndicator(color: Colors.cyan))
          else if (_customContactName.isNotEmpty && _customContactNumber.isNotEmpty)
            GestureDetector(
              onTap: () => _showCallConfirmation(_customContactName, _customContactNumber),
              child: Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.cyan, size: 24),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _customContactName,
                            style: TextStyle(color: Colors.white, fontSize: width * 0.032, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _customContactNumber,
                            style: TextStyle(color: Colors.cyan, fontSize: width * 0.028),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.call, color: Colors.cyan, size: width * 0.06),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _showAddContactDialog,
              child: Container(
                padding: EdgeInsets.all(width * 0.035),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.cyan),
                    SizedBox(width: width * 0.02),
                    Text(
                      "Add Emergency Contact",
                      style: TextStyle(color: Colors.cyan, fontSize: width * 0.032, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (_customContactName.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showAddContactDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: Colors.grey.shade400, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Edit Contact",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomsSection(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              "Critical Symptoms",
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: width * 0.03),
        ...symptoms.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> symptom = entry.value;
          bool isSelected = selectedSymptom == index;
          Color symptomColor = symptom['color'] as Color;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedSymptom = isSelected ? -1 : index;
              });
              if (!isSelected) {
                triggerEmergency();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: width * 0.025),
              padding: EdgeInsets.all(width * 0.035),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [symptomColor.withOpacity(0.4), symptomColor.withOpacity(0.2)])
                    : LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? symptomColor.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: symptomColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: BoxDecoration(
                      color: symptomColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(symptom['icon'], color: symptomColor, size: width * 0.06),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symptom['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          symptom['subtitle'],
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: width * 0.026,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: symptomColor, size: 24)
                  else
                    Icon(Icons.chevron_right, color: Colors.white38, size: 24),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActionsCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                "Quick Actions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  width,
                  Icons.phone,
                  "Call 112",
                  Colors.red,
                  () => _showCallConfirmation('Emergency', '112'),
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: _buildQuickActionButton(
                  width,
                  Icons.local_hospital,
                  "Find Hospital",
                  Colors.blue,
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(double width, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.035),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: width * 0.08),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: width * 0.03, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.15), Colors.amber.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                "Safety Tips",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          _buildTipItem(Icons.check, "Stay calm and assess the situation"),
          _buildTipItem(Icons.check, "Call 112 for multi-service emergency"),
          _buildTipItem(Icons.check, "Provide clear location to responders"),
          _buildTipItem(Icons.check, "Keep emergency contacts updated"),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.amber.shade200, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // EMERGENCY ACTIVE SCREEN
  Widget _buildEmergencyActive(double width) {
    return Column(
      children: [
        _buildEmergencyAppBar(width),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              children: [
                _buildEmergencyAlert(width),
                SizedBox(height: width * 0.04),
                _buildEmergencyActions(width),
                SizedBox(height: width * 0.04),
                _buildCurrentHealthData(width),
                SizedBox(height: width * 0.04),
                _buildCancelButton(width),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyAppBar(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.emergency, color: Colors.white, size: width * 0.06),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 EMERGENCY MODE ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Help is on the way',
                  style: TextStyle(color: Colors.white70, fontSize: width * 0.03),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning, color: Colors.white, size: width * 0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: Colors.white, size: width * 0.15),
            ),
          ),
          SizedBox(height: width * 0.04),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "CRITICAL EMERGENCY",
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.07,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(height: width * 0.02),
          Text(
            selectedSymptom >= 0 ? symptoms[selectedSymptom]['title'] : "Medical Emergency Detected",
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.04,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: width * 0.03),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Help is being dispatched",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActions(double width) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEmergencyButton(
                width,
                Icons.call,
                "Call 112",
                Colors.white,
                () => _showCallConfirmation('Emergency', '112'),
              ),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: _buildEmergencyButton(
                width,
                Icons.local_hospital,
                "Find Hospital",
                Colors.white,
                () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                },
              ),
            ),
          ],
        ),
        SizedBox(height: width * 0.03),
        Row(
          children: [
            Expanded(
              child: _buildEmergencyButton(
                width,
                Icons.share_location,
                "Share Location",
                Colors.white70,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location sharing initiated'), backgroundColor: Colors.green),
                  );
                },
              ),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: _buildEmergencyButton(
                width,
                Icons.message,
                "Notify Family",
                Colors.white70,
                () {
                  if (_customContactNumber.isNotEmpty) {
                    _showCallConfirmation(_customContactName, _customContactNumber);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add an emergency contact first'), backgroundColor: Colors.orange),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyButton(double width, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: width * 0.08),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: width * 0.03, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentHealthData(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                "Your Health Data (For Responders)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          Row(
            children: [
              _buildHealthDataItem(width, "❤️ Heart Risk", "${healthDataProvider.heartRisk.round()}%", Icons.favorite),
              _buildHealthDataItem(width, "😰 Stress", "${healthDataProvider.stressScore}%", Icons.psychology),
            ],
          ),
          Row(
            children: [
              _buildHealthDataItem(width, "😴 Sleep", "${healthDataProvider.sleepHours.round()}h", Icons.bedtime),
              _buildHealthDataItem(width, "📊 BMI", "${healthDataProvider.bmi.toStringAsFixed(1)}", Icons.monitor_weight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataItem(double width, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: EdgeInsets.all(width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: width * 0.05),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.white54, fontSize: width * 0.025),
                  ),
                  Text(
                    value,
                    style: TextStyle(color: Colors.white, fontSize: width * 0.035, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(double width) {
    return GestureDetector(
      onTap: cancelEmergency,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, color: Colors.white70, size: width * 0.05),
            const SizedBox(width: 8),
            Text(
              "Cancel Emergency / False Alarm",
              style: TextStyle(color: Colors.white70, fontSize: width * 0.035),
            ),
          ],
        ),
      ),
    );
  }
}
