import 'package:flutter/material.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() =>
      _SurveyScreenState(); // Fixed return type
}

class _SurveyScreenState extends State<SurveyScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              // Handle submission
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            Step(
              title: const Text('Step 1'),
              content: const Text('Content for Step 1'),
            ),
            Step(
              title: const Text('Step 2'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Content for Step 2'),
                  // Place the aerator form content here
                ],
              ),
            ),
            Step(
              title: const Text('Step 3'),
              content: const Text('Content for Step 3'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
