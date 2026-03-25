import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/voice_service.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/utils/responsive.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {

  final TextEditingController controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  final AIService aiService = AIService();
  final ScrollController _scrollController = ScrollController();
  final VoiceService voiceService = VoiceService();

  bool isLoading = false;
  bool isListening = false;
  bool isSpeaking = false;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  // Quick actions categories
  final List<Map<String, dynamic>> quickActions = [
    {'title': 'Common Cold', 'icon': Icons.ac_unit, 'query': 'What are common cold symptoms?'},
    {'title': 'Fever Help', 'icon': Icons.thermostat, 'query': 'How to reduce fever naturally?'},
    {'title': 'Healthy Diet', 'icon': Icons.restaurant, 'query': 'What are healthy diet tips?'},
    {'title': 'Exercise', 'icon': Icons.fitness_center, 'query': 'What are good exercise recommendations?'},
    {'title': 'Headache', 'icon': Icons.psychology, 'query': 'What causes headaches and how to treat them?'},
    {'title': 'Sleep Tips', 'icon': Icons.bedtime, 'query': 'How to improve sleep quality?'},
  ];

  @override
  void initState() {
    super.initState();
    _initVoiceService();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  void _initVoiceService() {
    voiceService.initSpeech();
    
    voiceService.onTextChanged = (text) {
      controller.text = text;
    };
    
    voiceService.onListeningStateChanged = (listening) {
      setState(() {
        isListening = listening;
      });
      if (listening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    };
    
    voiceService.onSpeakingStateChanged = (speaking) {
      setState(() {
        isSpeaking = speaking;
      });
    };
  }

  @override
  void dispose() {
    controller.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    voiceService.dispose();
    super.dispose();
  }

  void sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"text": text, "isUser": true, "timestamp": DateTime.now()});
      controller.clear();
      isLoading = true;
    });

    _scrollToBottom();

    final response = await aiService.sendMessage(text);

    setState(() {
      messages.add({"text": response, "isUser": false, "timestamp": DateTime.now()});
      isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void toggleVoice() {
    if (isListening) {
      voiceService.stopListening();
    } else {
      voiceService.startListening();
    }
  }

  void toggleSpeaking() {
    if (isSpeaking) {
      voiceService.stopSpeaking();
    } else if (messages.isNotEmpty) {
      final lastAiMessage = messages.lastWhere(
        (msg) => !msg["isUser"],
        orElse: () => {"text": ""},
      );
      if (lastAiMessage["text"].isNotEmpty) {
        voiceService.speak(lastAiMessage["text"]);
      }
    }
  }

  void _sendQuickAction(String query) {
    controller.text = query;
    sendMessage();
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth.clamp(0.0, 520.0).toDouble();
    double height = MediaQuery.of(context).size.height;

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
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
            children: [
              _buildAppBar(width),
              
              // Welcome Message or Messages
              if (messages.isEmpty && !isLoading)
                Expanded(
                  child: _buildWelcomeScreen(width, height),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(width * 0.04, width * 0.02, width * 0.04, width * 0.02),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isLoading && index == messages.length) {
                        return _buildLoadingMessage(width);
                      }
                      
                      final msg = messages[index];
                      return _buildMessageBubble(msg, width);
                    },
                  ),
                ),

              // Loading indicator
              if (isLoading && messages.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: _buildLoadingMessage(width),
                ),

              _buildInputArea(width),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        children: [
          Row(
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
              SizedBox(width: width * 0.03),
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.health_and_safety, color: Colors.white, size: width * 0.06),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Health Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: width * 0.01),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: width * 0.028,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isListening ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: toggleVoice,
                      child: Container(
                        padding: EdgeInsets.all(width * 0.025),
                        decoration: BoxDecoration(
                          color: isListening ? Colors.red : Colors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: isListening
                              ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 15)]
                              : null,
                        ),
                        child: Icon(
                          isListening ? Icons.stop : Icons.mic,
                          color: isListening ? Colors.white : Colors.cyan,
                          size: width * 0.05,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBadge("🤖 AI Powered", Colors.purple),
                SizedBox(width: width * 0.02),
                _buildBadge("⚡ Real-time", Colors.orange),
                SizedBox(width: width * 0.02),
                _buildBadge("📱 24/7 Available", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(double width, double height) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        children: [
          // AI Animation Container
          _buildAIHeader(width),
          SizedBox(height: width * 0.04),
          
          // Quick Actions
          Text(
            "Quick Actions",
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
            children: quickActions.map((action) => _buildQuickAction(
              action['title'],
              action['icon'],
              action['query'],
            )).toList(),
          ),
          
          SizedBox(height: width * 0.04),
          
          // Capabilities
          _buildCapabilitiesCard(width),
          
          SizedBox(height: width * 0.04),
          
          // Disclaimer
          _buildDisclaimerCard(width),
        ],
      ),
    );
  }

  Widget _buildAIHeader(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(0.2),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _waveController.value * 6.28,
                child: Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.smart_toy, color: Colors.white, size: width * 0.12),
                ),
              );
            },
          ),
          SizedBox(height: width * 0.03),
          Text(
            "Hello! I'm your AI Health Assistant",
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.02),
          Text(
            "I can help you with health-related questions, symptom analysis, and general wellness advice.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.032,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: width * 0.03),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: width * 0.025,
            ),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, color: Colors.cyan, size: width * 0.04),
                SizedBox(width: width * 0.02),
                Text(
                  "Tap mic to speak",
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: width * 0.032,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text, IconData icon, String query) {
    return GestureDetector(
      onTap: () => _sendQuickAction(query),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyan.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.cyan, size: 18),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: Colors.cyan, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.2), Colors.indigo.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                "What I Can Help With",
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.035,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          _buildCapabilityItem("🩺 Symptom Analysis", "Describe your symptoms"),
          _buildCapabilityItem("💊 Medication Info", "Learn about medicines"),
          _buildCapabilityItem("🥗 Nutrition Advice", "Healthy eating tips"),
          _buildCapabilityItem("🧘 Wellness Tips", "Mental & physical health"),
          _buildCapabilityItem("📋 Health Reports", "Understand your reports"),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: width * 0.05),
          SizedBox(width: width * 0.02),
          Expanded(
            child: Text(
              "Always consult healthcare professionals for medical advice",
              style: TextStyle(
                color: Colors.amber,
                fontSize: width * 0.028,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, double width) {
    bool isUser = msg["isUser"] as bool;
    
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.03),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.78),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  gradient: isUser 
                    ? const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF0099FF)])
                    : LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.1)]),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isUser ? Radius.circular(20) : Radius.circular(5),
                    bottomRight: isUser ? Radius.circular(5) : Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser ? Colors.cyan.withOpacity(0.3) : Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isUser) ...[
                          Icon(Icons.smart_toy, color: Colors.cyan, size: width * 0.04),
                          SizedBox(width: width * 0.02),
                        ],
                        Text(
                          isUser ? "You" : "Health AI",
                          style: TextStyle(
                            color: isUser ? Colors.white70 : Colors.cyan,
                            fontSize: width * 0.028,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isUser) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              if (!isSpeaking) {
                                voiceService.speak(msg["text"]);
                              } else {
                                voiceService.stopSpeaking();
                              }
                            },
                            child: Icon(
                              isSpeaking ? Icons.stop : Icons.volume_up,
                              color: Colors.cyan,
                              size: width * 0.04,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: width * 0.02),
                    Text(
                      msg["text"] as String,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.white70,
                        fontSize: width * 0.035,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMessage(double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.03),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.78),
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.cyan,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                "Thinking...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: width * 0.032,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(double width) {
    return Container(
      margin: EdgeInsets.all(width * 0.04),
      padding: EdgeInsets.all(width * 0.015),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white10, Colors.white12],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: Colors.black87, fontSize: width * 0.04),
                decoration: InputDecoration(
                  hintText: isListening ? "Listening..." : "Ask about symptoms, medicines, health...",
                  hintStyle: TextStyle(
                    color: isListening ? Colors.cyan.shade700 : Colors.black45,
                    fontSize: width * 0.035,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04),
                ),
                onSubmitted: (text) => sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: toggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? Colors.red : Colors.cyan.withOpacity(0.2),
                boxShadow: isListening
                    ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10)]
                    : null,
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: isListening ? Colors.white : Colors.cyan,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
