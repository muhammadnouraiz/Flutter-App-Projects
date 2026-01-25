// File: lib/views/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controller to programmatically swipe pages (Next Button)
  final PageController _controller = PageController();
  int _page = 0; // Tracks current slide index (0, 1, or 2)

  // Data Source: Content for the 3 tutorial slides
  final List<Map<String, String>> slides = [
    {'title': 'Track your skills easily', 'subtitle': 'Add skills, set targets and log notes to measure your growth', 'image': 'assets/images/onboarding1.png'},
    {'title': 'Turn note into progress', 'subtitle': 'Write a quick note after each learning session — we will track progress for you', 'image': 'assets/images/onboarding2.png'},
    {'title': 'Earn badges & stay motivated', 'subtitle': 'Complete goals and unlock achievements along you learning journey', 'image': 'assets/images/onboarding3.png'},
  ];

  // Logic: Completion Handler.
  // 1. Opens Hive box.
  // 2. Sets 'hasSeenOnboarding' to true (so this screen never shows again).
  // 3. Navigates to Login Screen.
  void _finish() async {
    final box = await Hive.openBox('userBox');
    await box.put('hasSeenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Column(
          children: [
            // UI Component: The sliding area containing Image and Text
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // UI: The illustration
                        Image.asset(s['image']!, width: 220, height: 220),
                        const SizedBox(height: 24),
                        // UI: The bold title text
                        Text(s['title']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        // UI: The grey subtitle text
                        Text(s['subtitle']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // UI Component: The Page Indicators (Dots)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(slides.length, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                // Logic: Active dot is wider (18) and Orange. Inactive is small (8) and Grey.
                width: _page == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(color: _page == i ? const Color(0xFFFF6B4A) : Colors.grey[300], borderRadius: BorderRadius.circular(20)),
              );
            })),

            // UI Component: Bottom Navigation Bar (Skip | Next)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Row(
                children: [
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
                    onPressed: () {
                      // Logic: If on the last slide, Finish. Otherwise, go to next slide.
                      if (_page == slides.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                      }
                    },
                    // UI: Changes text from "Next" to "Get Started" on the last slide
                    child: Text(_page == slides.length - 1 ? 'Get Started' : 'Next'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}