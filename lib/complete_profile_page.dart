import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
  

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  String sex = "male";
  bool loading = false;

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => loading = true);

    final height = double.tryParse(heightController.text) ?? 0;
    final weight = double.tryParse(weightController.text) ?? 0;

    final goal = _calculateStepGoal(height, weight, sex);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      "heightCm": height,
      "weightKg": weight,
      "sex": sex,
      "dailyStepGoal": goal,
      "profileComplete": true,
    });

    setState(() => loading = false);
  }

  int _calculateStepGoal(double height, double weight, String sex) {
    // baseline
    int base = 7000;

    // adjust for weight
    if (weight > 90) base += 2000;
    if (weight < 60) base -= 1000;

    // adjust for height (stride proxy)
    if (height > 180) base += 500;
    if (height < 160) base -= 500;

    // sex adjustment (optional tuning)
    if (sex == "male") base += 500;

    return base.clamp(4000, 15000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Height (cm)"),
            ),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Weight (kg)"),
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: sex,
              items: ["male", "female"]
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => sex = value!);
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: Text(loading ? "Saving..." : "Continue"),
            )
          ],
        ),
      ),
    );
  }
}