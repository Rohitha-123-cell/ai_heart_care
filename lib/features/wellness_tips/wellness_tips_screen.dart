import 'package:flutter/material.dart';
import '../step_counter/step_counter_screen.dart';

class WellnessTipsScreen extends StatefulWidget {
  const WellnessTipsScreen({super.key});

  @override
  State<WellnessTipsScreen> createState() => _WellnessTipsScreenState();
}

class _WellnessTipsScreenState extends State<WellnessTipsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<Map<String, dynamic>> tips = [
    {
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'gradient': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
      'title': 'Stay Hydrated',
      'description': 'Drink at least 8 glasses of water daily. Proper hydration helps maintain body temperature, lubricates joints, and aids digestion.',
      'tip': 'Start your day with a glass of warm water with lemon!',
      'emoji': '💧',
      'category': 'Nutrition',
    },
    {
      'icon': Icons.self_improvement,
      'color': Colors.purple,
      'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      'title': 'Practice Mindfulness',
      'description': 'Take 10-15 minutes daily for meditation or deep breathing exercises to reduce stress and improve mental clarity.',
      'tip': 'Try the 4-7-8 breathing technique before bed.',
      'emoji': '🧘',
      'category': 'Mental',
    },
    {
      'icon': Icons.directions_run,
      'color': Colors.green,
      'gradient': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      'title': 'Daily Exercise',
      'description': 'Aim for 30 minutes of moderate exercise daily. Walking, cycling, or swimming can significantly improve your cardiovascular health.',
      'tip': 'Take a 15-minute walk after each meal.',
      'emoji': '🏃',
      'category': 'Fitness',
    },
    {
      'icon': Icons.bedtime,
      'color': Colors.indigo,
      'gradient': [const Color(0xFF3a1c71), const Color(0xFFd76d77)],
      'title': 'Quality Sleep',
      'description': 'Adults need 7-9 hours of quality sleep. Establish a consistent sleep schedule and create a restful environment.',
      'tip': 'Avoid screens 1 hour before sleeping.',
      'emoji': '😴',
      'category': 'Mental',
    },
    {
      'icon': Icons.restaurant_menu,
      'color': Colors.orange,
      'gradient': [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      'title': 'Balanced Diet',
      'description': 'Include fruits, vegetables, whole grains, and lean proteins in your meals. Limit processed foods and added sugars.',
      'tip': 'Fill half your plate with vegetables at lunch and dinner.',
      'emoji': '🥗',
      'category': 'Nutrition',
    },
    {
      'icon': Icons.favorite,
      'color': Colors.red,
      'gradient': [const Color(0xFFeb3349), const Color(0xFFf45c43)],
      'title': 'Heart Health',
      'description': 'Monitor your blood pressure and cholesterol levels regularly. Reduce sodium intake and avoid smoking.',
      'tip': 'Include omega-3 rich foods like fish and walnuts.',
      'emoji': '❤️',
      'category': 'Nutrition',
    },
    {
      'icon': Icons.psychology,
      'color': Colors.teal,
      'gradient': [const Color(0xFF0F2027), const Color(0xFF2C5364)],
      'title': 'Mental Health',
      'description': 'Stay socially connected with friends and family. Engage in activities you enjoy and seek help when feeling overwhelmed.',
      'tip': 'Keep a gratitude journal - write 3 things daily.',
      'emoji': '🧠',
      'category': 'Mental',
    },
    {
      'icon': Icons.visibility,
      'color': Colors.amber,
      'gradient': [const Color(0xFFf7971e), const Color(0xFFffd200)],
      'title': 'Eye Care',
      'description': 'Follow the 20-20-20 rule: Every 20 minutes, look at something 20 feet away for 20 seconds.',
      'tip': 'Wear sunglasses outdoors to protect from UV rays.',
      'emoji': '👁️',
      'category': 'Nutrition',
    },
    {
      'icon': Icons.medical_services,
      'color': Colors.cyan,
      'gradient': [const Color(0xFF00D2FF), const Color(0xFF3A7BD5)],
      'title': 'Regular Check-ups',
      'description': 'Schedule annual health screenings and dental check-ups. Early detection can prevent serious health issues.',
      'tip': 'Keep a health diary to track symptoms.',
      'emoji': '🏥',
      'category': 'Nutrition',
    },
    {
      'icon': Icons.sanitizer,
      'color': Colors.pink,
      'gradient': [const Color(0xFFee9ca7), const Color(0xFFffdde1)],
      'title': 'Hand Hygiene',
      'description': 'Wash your hands frequently with soap for at least 20 seconds. This simple habit prevents many infections.',
      'tip': 'Use hand sanitizer when soap isn\'t available.',
      'emoji': '🧴',
      'category': 'Nutrition',
    },
    {
      'icon': Icons.air,
      'color': Colors.lightBlue,
      'gradient': [const Color(0xFF74ebd5), const Color(0xFFACB6E5)],
      'title': 'Posture Check',
      'description': 'Maintain good posture while sitting and standing. Take breaks to stretch if you work at a desk.',
      'tip': 'Set reminders to stand up and stretch every hour.',
      'emoji': '🧘‍♀️',
      'category': 'Fitness',
    },
    {
      'icon': Icons.smoke_free,
      'color': Colors.brown,
      'gradient': [const Color(0xFF8B4513), const Color(0xFFD2691E)],
      'title': 'Avoid Tobacco',
      'description': 'Tobacco use increases risk of heart disease, cancer, and respiratory problems. Seek support to quit if needed.',
      'tip': 'Replace smoking breaks with a short walk.',
      'emoji': '🚭',
      'category': 'Nutrition',
    },
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFF8E37D7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Beautiful Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(width * 0.025),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
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
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.amber, Colors.orange],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                    ),
                                    SizedBox(width: 12),
                                    const Text(
                                      'Wellness Tips',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Expert health advice for a better you',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Featured Tip Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                  padding: EdgeInsets.all(width * 0.05),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.9),
                        Colors.orange.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tips[_selectedIndex]['emoji'],
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                      SizedBox(width: width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Tip",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              tips[_selectedIndex]['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              tips[_selectedIndex]['tip'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: height * 0.03),
              
              // Category Pills
              Container(
                height: 45,
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final categories = ['All', 'Nutrition', 'Fitness', 'Mental'];
                    final icons = [Icons.apps, Icons.restaurant, Icons.fitness_center, Icons.psychology];
                    final isSelected = _selectedCategory == index;
                    return GestureDetector(
                      onTap: () {
                        if (index == 2) { // Fitness
                          // Navigate to Step Counter screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StepCounterScreen()),
                          );
                        } else {
                          setState(() => _selectedCategory = index);
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [Colors.white, Colors.white70])
                              : LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icons[index],
                              color: isSelected ? const Color(0xFF667eea) : Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              categories[index],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF667eea) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: height * 0.02),
              
              // Tips List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.all(width * 0.05),
                    itemCount: _getFilteredTips().length,
                    itemBuilder: (context, index) {
                      final tip = _getFilteredTips()[index];
                      return _buildTipCard(tip, width, index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedCategory = 0;

  List<Map<String, dynamic>> _getFilteredTips() {
    final categories = ['All', 'Nutrition', 'Fitness', 'Mental'];
    final selectedCategory = categories[_selectedCategory];
    
    if (_selectedCategory == 0) {
      // All - return all tips
      return tips;
    } else {
      // Filter by category
      return tips.where((tip) => tip['category'] == selectedCategory).toList();
    }
  }

  Widget _buildTipCard(Map<String, dynamic> tip, double width, int index) {
    final colors = tip['gradient'] as List<Color>;
    final color = tip['color'] as Color;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: width * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors[0].withOpacity(0.3),
              colors[1].withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _selectedIndex == index 
                ? color.withOpacity(0.8) 
                : Colors.white24,
            width: _selectedIndex == index ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedIndex == index 
                  ? color.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.1),
              blurRadius: _selectedIndex == index ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.035),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors[0], colors[1]],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      tip['icon'] as IconData,
                      color: Colors.white,
                      size: width * 0.07,
                    ),
                  ),
                  SizedBox(width: width * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tip['emoji'],
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip['title'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: width * 0.01),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.03,
                            vertical: width * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tip ${index + 1}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.025,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(width * 0.02),
                    decoration: BoxDecoration(
                      color: _selectedIndex == index 
                          ? Colors.green.withOpacity(0.3) 
                          : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedIndex == index ? Icons.check : Icons.fiber_manual_record,
                      color: _selectedIndex == index ? Colors.green : Colors.white38,
                      size: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: width * 0.04),
              Text(
                tip['description'] as String,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: width * 0.032,
                  height: 1.5,
                ),
              ),
              SizedBox(height: width * 0.03),
              Container(
                padding: EdgeInsets.all(width * 0.035),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.withOpacity(0.3), Colors.orange.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(
                        tip['tip'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.03,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
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
}
