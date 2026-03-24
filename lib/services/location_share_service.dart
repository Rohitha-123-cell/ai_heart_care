import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Model for a contact to share location with
class EmergencyContact {
  final String name;
  final String phoneNumber;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
  });
}

/// Service for sharing location via WhatsApp
class LocationShareService {
  static const Color _primaryColor = Color(0xFF2F80ED);
  static const Color _successColor = Color(0xFF27AE60);

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  /// Share location via WhatsApp to selected contacts
  static Future<bool> shareLocationViaWhatsApp(
    List<EmergencyContact> selectedContacts,
    Position location,
  ) async {
    if (selectedContacts.isEmpty) return false;

    // Create Google Maps URL for the location
    final googleMapsUrl = 
        'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    
    // Create message with location
    final message = 'My current location:\n$googleMapsUrl\n\n'
        'Sent from AI Health Guardian app';
    
    // Encode the message for URL
    final encodedMessage = Uri.encodeComponent(message);
    
    bool allSuccessful = true;
    
    // Send to each selected contact via WhatsApp
    for (final contact in selectedContacts) {
      final phoneNumber = contact.phoneNumber
          .replaceAll(RegExp(r'[^\d+]'), '');
      
      // Try to open WhatsApp
      final whatsappUrl = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';
      final fallbackUrl = 'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
      
      try {
        // Try direct WhatsApp URL scheme first
        final canLaunchWhatsapp = await canLaunchUrl(Uri.parse(whatsappUrl));
        if (canLaunchWhatsapp) {
          await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
        } else {
          // Fallback to web WhatsApp
          await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint("Error sharing to WhatsApp: $e");
        allSuccessful = false;
      }
    }
    
    return allSuccessful;
  }

  /// Generate shareable location message
  static String generateLocationMessage(Position location, {String? customMessage}) {
    final googleMapsUrl = 
        'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    
    final timestamp = DateTime.now().toString().substring(0, 16);
    
    return '📍 *My Current Location*\n\n'
        '$googleMapsUrl\n\n'
        '📅 Time: $timestamp\n'
        '${customMessage ?? "Sent from AI Health Guardian app"}';
  }

  /// Show contact selection dialog
  static Future<List<EmergencyContact>?> showContactSelectionDialog(
    BuildContext context,
  ) async {
    return await showModalBottomSheet<List<EmergencyContact>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContactSelectionSheet(),
    );
  }
}

/// Bottom sheet for selecting emergency contacts
class ContactSelectionSheet extends StatefulWidget {
  const ContactSelectionSheet({super.key});

  @override
  State<ContactSelectionSheet> createState() => _ContactSelectionSheetState();
}

class _ContactSelectionSheetState extends State<ContactSelectionSheet> {
  final List<EmergencyContact> _selectedContacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isNotEmpty && phone.isNotEmpty) {
      setState(() {
        _selectedContacts.add(EmergencyContact(
          name: name,
          phoneNumber: phone,
        ));
        _nameController.clear();
        _phoneController.clear();
      });
    }
  }

  void _removeContact(int index) {
    setState(() {
      _selectedContacts.removeAt(index);
    });
  }

  /// Send location to a specific contact when tapped
  void _sendToContact(EmergencyContact contact) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF25D366),
        ),
      ),
    );

    // Get location
    final location = await LocationShareService.getCurrentLocation();
    
    if (!mounted) return;
    
    // Close loading dialog
    Navigator.pop(context);

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Please check permissions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create Google Maps URL for the location
    final googleMapsUrl = 
        'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    
    // Create message with location
    final message = 'My current location:\n$googleMapsUrl\n\n'
        'Sent from AI Health Guardian app';
    
    // Encode the message for URL
    final encodedMessage = Uri.encodeComponent(message);
    
    final phoneNumber = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Try to open WhatsApp
    final whatsappUrl = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';
    final fallbackUrl = 'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
    
    try {
      final canLaunchWhatsapp = await canLaunchUrl(Uri.parse(whatsappUrl));
      if (canLaunchWhatsapp) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web WhatsApp
        await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error sharing to WhatsApp: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please make sure it is installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareLocation() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one contact'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get location
    final location = await LocationShareService.getCurrentLocation();
    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Share via WhatsApp
    if (mounted) {
      Navigator.pop(context, _selectedContacts);
    }
    
    await LocationShareService.shareLocationViaWhatsApp(
      _selectedContacts,
      location,
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.share_location, color: Color(0xFF2F80ED)),
                const SizedBox(width: 8),
                const Text(
                  'Share Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2F80ED)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add up to 2 emergency contacts to share your location via WhatsApp',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add contact form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _selectedContacts.length < 2 ? _addContact : null,
                      icon: const Icon(Icons.add_circle),
                      color: const Color(0xFF2F80ED),
                      iconSize: 36,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selected contacts list - Clickable to send immediately
          if (_selectedContacts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Tap a contact to send location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedContacts.length}/2',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Location will be sent automatically via WhatsApp',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = _selectedContacts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFF25D366),
                    child: InkWell(
                      onTap: () => _sendToContact(contact),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF25D366),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    contact.phoneNumber,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'No contacts added yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
