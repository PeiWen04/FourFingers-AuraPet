import 'package:flutter/material.dart';
import '../utils/app_settings.dart';
import '../services/user_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedBackground = 'assets/companion-bg.png';
  String selectedPet = 'assets/penguin.png';
  String initialBackground = 'assets/companion-bg.png';
  String initialPet = 'assets/penguin.png';
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final bg = AppSettings.getBackground();
    final pet = AppSettings.getPet();
    setState(() {
      selectedBackground = bg;
      selectedPet = pet;
      initialBackground = bg;
      initialPet = pet;
    });
  }

  bool get hasChanges =>
      selectedBackground != initialBackground || selectedPet != initialPet;

  void _saveSettings() async {
    if (!hasChanges) return;

    AppSettings.saveBackground(selectedBackground);
    AppSettings.savePet(selectedPet);

    // Save avatar to Firestore for persistence across devices
    try {
      await _userService.saveAvatar(selectedPet);
    } catch (e) {
      print('Error saving avatar to Firestore: $e');
    }

    setState(() {
      initialBackground = selectedBackground;
      initialPet = selectedPet;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Settings saved successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> backgrounds = [
    {'name': 'Companion', 'path': 'assets/companion-bg.png'},
    {'name': 'Welcome', 'path': 'assets/welcome-bg.png'},
    {'name': 'Mood', 'path': 'assets/bg-mood.png'},
  ];

  final List<Map<String, String>> pets = [
    {'name': 'Penguin', 'path': 'assets/penguin.png'},
    {'name': 'Owl', 'path': 'assets/owl.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple.shade400,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Background Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: backgrounds.map((bg) {
              final isSelected = selectedBackground == bg['path'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBackground = bg['path']!;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal.shade400
                                  : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(bg['path']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bg['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.teal.shade700
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI Pet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: pets.map((pet) {
              final isSelected = selectedPet == pet['path'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPet = pet['path']!;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal.shade400
                                  : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Image.asset(
                              pet['path']!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pet['name']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.teal.shade700
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (hasChanges) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
