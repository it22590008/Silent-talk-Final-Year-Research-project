import 'package:flutter/material.dart';

class AlphabetDisplay extends StatefulWidget {
  const AlphabetDisplay({super.key});

  @override
  State<AlphabetDisplay> createState() => _AlphabetDisplayState();
}

class _AlphabetDisplayState extends State<AlphabetDisplay> {
  int currentIndex = 0;

  final List<String> alphabets =
  List.generate(26, (index) => String.fromCharCode(65 + index));

  void nextLetter() {
    if (currentIndex < alphabets.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {

    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = alphabets[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alphabet"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo
            SizedBox(
              height: 100,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 10),

            // Alphabet Image
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/alphabets/$letter.png',
                    height: 350,
                  ),
                  const SizedBox(height: 10),

                  // Letter Display
                  Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextLetter,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  currentIndex == alphabets.length - 1
                      ? 'Go to Training'
                      : 'Next',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
