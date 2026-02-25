import 'package:flutter/material.dart';
import '../main.dart';
import '../services/user_service.dart';

class PetSelectionPage extends StatefulWidget {
  const PetSelectionPage({super.key});

  @override
  State<PetSelectionPage> createState() => _PetSelectionPageState();
}

class _PetSelectionPageState extends State<PetSelectionPage> {
  String? selectedPet;
  final UserService _userService = UserService();

  final List<Map<String, String>> pets = [
    {'name': 'Penguin', 'image': 'assets/penguin.png'},
    {'name': 'Owl', 'image': 'assets/owl.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/companion-bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Title in white container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Select Your AI Pet Companion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Pet selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: pets.map((pet) {
                  final isSelected = selectedPet == pet['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPet = pet['name'];
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal.shade400
                                  : Colors.black.withOpacity(0.6),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            pet['image']!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.pets, size: 100);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pet['name']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.teal.shade700
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const Spacer(flex: 1),

              // Confirm button
              if (selectedPet != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Save companion selection and avatar to Firestore
                      try {
                        await _userService.saveCompanionSelection(selectedPet!);

                        // Save the corresponding avatar
                        final avatarPath = selectedPet == 'Owl'
                            ? 'assets/owl.png'
                            : 'assets/penguin.png';
                        await _userService.saveAvatar(avatarPath);
                      } catch (e) {
                        print('Error saving companion: $e');
                      }

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(
                            title: 'AuraPet',
                            initialIndex: 0,
                            showFirstTimeInfo: true,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
