import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _loading = true;
  List<Map<String, dynamic>> _diagnoses = [];

  @override
  void initState() {
    super.initState();
    _loadDiagnoses();
  }

  Future<void> _loadDiagnoses() async {
    try {
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('diagnoses')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      final List<Map<String, dynamic>> list = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        list.add({
          'title': data['title'] ?? 'Unknown Diagnosis',
          'date': data['date'] != null
              ? DateFormat(
                  'MMM dd, yyyy',
                ).format((data['date'] as Timestamp).toDate())
              : 'Unknown Date',
          'diseaseName': data['diseaseName'] ?? 'Unknown',
          'confidence': data['confidence'] ?? 0.0,
        });
      }

      if (mounted) {
        setState(() {
          _diagnoses = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load diagnoses: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToUpload() {
    Navigator.pushNamed(context, '/upload');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToDiagnosisHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Diagnosis history will be implemented soon"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName =
        user?.displayName ?? user?.email?.split('@').first ?? "User";

    return Scaffold(
      body: Stack(
        children: [
          // Background with overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/tabib_background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),

          // Content with Scroll
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),

                // Header with welcome and avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Colors.blue),
                        onPressed: _navigateToProfile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Upload Image Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToUpload,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      "Upload Skin Image", // تغيير النص ليتناسب مع الأمراض الجلدية
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Recent Diagnoses Section
                const Text(
                  "Recent Diagnoses",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _diagnoses.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "No diagnoses yet. Upload an image to get started!",
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _diagnoses.length,
                          itemBuilder: (context, index) {
                            final diagnosis = _diagnoses[index];
                            return _diagnosisCard(diagnosis);
                          },
                        ),
                      ),

                const SizedBox(height: 30),

                // Quick Actions Section
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionButton(
                      Icons.camera_alt,
                      "New Scan",
                      _navigateToUpload,
                    ),
                    _actionButton(
                      Icons.history,
                      "History",
                      _navigateToDiagnosisHistory,
                    ),
                    _actionButton(Icons.logout, "Logout", _logout),
                  ],
                ),

                const SizedBox(height: 30),

                // Additional Space for More Content
                // يمكن إضافة أقسام إضافية هنا بدون مشاكل

                // Health Tip - معدل للأمراض الجلدية
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "👩‍⚕️ Skin Care Tip:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Regular skin checks help in early detection of skin conditions. Always consult a dermatologist for accurate diagnosis.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // يمكن إضافة المزيد من المحتوى هنا
                // Example: Statistics Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📊 Your Statistics",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            "Total Scans",
                            _diagnoses.length.toString(),
                          ),
                          _statItem("This Month", "0"),
                          _statItem("Accuracy", "-"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagnosisCard(Map<String, dynamic> diagnosis) {
    final String diseaseName = diagnosis['diseaseName'] ?? 'Unknown';
    final String date = diagnosis['date'] ?? 'Unknown Date';
    final double confidence = diagnosis['confidence'] ?? 0.0;

    Color cardColor = _getDiseaseColor(diseaseName);

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            diseaseName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          Text(
            '${(confidence * 100).toStringAsFixed(1)}% confident',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            date,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDiseaseColor(String diseaseName) {
    diseaseName = diseaseName.toLowerCase();

    if (diseaseName.contains('healthy') || diseaseName.contains('normal')) {
      return Colors.green;
    } else if (diseaseName.contains('mild') || diseaseName.contains('early')) {
      return Colors.orange;
    } else if (diseaseName.contains('severe') ||
        diseaseName.contains('advanced')) {
      return Colors.red;
    } else if (diseaseName.contains('acne')) {
      return Colors.purple;
    } else if (diseaseName.contains('eczema')) {
      return Colors.blue;
    } else if (diseaseName.contains('psoriasis')) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 28, color: Colors.blue),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}
