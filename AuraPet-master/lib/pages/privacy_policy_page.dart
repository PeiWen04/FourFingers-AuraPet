import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                    'AuraPet respects your privacy and is committed to protecting your personal data in accordance with the Personal Data Protection Act 2010 (PDPA/PDPR) of Malaysia.',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const Divider(height: 40),

                  _buildSection(
                    '1. Data Collected',
                    'AuraPet may collect the following information during registration and usage:\n'
                        '• Basic account information (e.g. username, email address)\n'
                        '• Mood entries, diary inputs, and app interaction data\n'
                        '• App usage data for system improvement and analytics\n\n'
                        'AuraPet does not collect sensitive personal data beyond what is necessary for emotional wellness features.',
                  ),

                  _buildSection(
                    '2. Purpose of Data Collection',
                    'Your data is collected and used to:\n'
                        '• Provide personalized emotional wellness features\n'
                        '• Enable AI companion interaction and mood tracking\n'
                        '• Improve system performance and user experience\n'
                        '• Ensure application security and reliability',
                  ),

                  _buildSection(
                    '3. Data Storage and Protection',
                    'All user data is stored securely using appropriate technical and organizational measures to prevent unauthorized access, disclosure, or misuse.',
                  ),

                  _buildSection(
                    '4. Data Sharing',
                    'AuraPet does not sell or share personal data with third parties. Data is only accessed by authorized administrators for system maintenance and improvement purposes.',
                  ),

                  _buildSection(
                    '5. User Rights',
                    'In accordance with PDPR, users have the right to:\n'
                        '• Access and review their personal data\n'
                        '• Update or correct inaccurate information\n'
                        '• Request the deletion of their account and personal data',
                  ),

                  _buildSection(
                    '6. Disclaimer',
                    'AuraPet is designed to support emotional wellness and does not replace professional medical or mental health services.',
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Bottom Action Bar (Same as T&C)
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
              color: Colors.blueAccent, // Matches T&C style
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}