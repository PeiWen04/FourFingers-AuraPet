import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'By creating an account and using AuraPet, you agree to the following terms and conditions:',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const Divider(height: 40),

                  _buildSection(
                    '1. Intended Use',
                    'AuraPet is a digital emotional wellness application intended to support stress management, emotional reflection, and relaxation. It is not a medical or diagnostic tool.',
                  ),

                  _buildSection(
                    '2. User Responsibility',
                    'Users agree to:\n'
                        '• Provide accurate account information\n'
                        '• Use the application responsibly and ethically\n'
                        '• Not misuse the platform for harmful, illegal, or abusive activities',
                  ),

                  _buildSection(
                    '3. AI Companion Limitation',
                    'The AI companion provides general emotional support only. AI generates responses and should not be considered professional advice.',
                  ),

                  _buildSection(
                    '4. Account Security',
                    'Users are responsible for maintaining the confidentiality of their login credentials.',
                  ),

                  _buildSection(
                    '5. Service Availability',
                    'AuraPet strives for continuous availability but does not guarantee uninterrupted access due to maintenance or technical issues.',
                  ),

                  _buildSection(
                    '6. Modifications',
                    'AuraPet reserves the right to update features, content, or these terms at any time. Continued use indicates acceptance of updated terms.',
                  ),

                  _buildSection(
                    '7. Governing Law',
                    'These terms are governed by and interpreted in accordance with the laws of Malaysia, including the Personal Data Protection Act 2010.',
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Optional: Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blueAccent, // Matches the section headers
                  foregroundColor: Colors.white,
                ),
                child: const Text('I Understand'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent, // Distinct color for T&C headers
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}