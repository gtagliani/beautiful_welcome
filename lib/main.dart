import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const BeautifulWelcomeApp());
}

class BeautifulWelcomeApp extends StatelessWidget {
  const BeautifulWelcomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beautiful Welcome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 15),
        vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Moving Objects
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: List.generate(6, (index) {
                  return Positioned(
                    left: _getLeftPos(index, _controller.value, size.width),
                    top: _getTopPos(index, _controller.value, size.height),
                    child: child ?? _buildFloatingObject(index),
                  );
                }),
              );
            },
          ),
          
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to\nBeautiful Flutter App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A magical experience awaits',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E3192),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getLeftPos(int index, double progress, double width) {
    final baseProgress = (progress + (index * 0.15)) % 1.0;
    // Move slightly outside bounds and across viewport smoothly
    return index % 2 == 0 
        ? width * (baseProgress - 0.2) * 1.5
        : width * (1.2 - baseProgress) * 1.5;
  }

  double _getTopPos(int index, double progress, double height) {
    final baseConfig = [0.1, 0.3, 0.5, 0.7, 0.8, 0.2];
    // Add wave movement on Y axis
    return height * baseConfig[index] + sin(progress * 2 * pi + index) * 60;
  }

  Widget _buildFloatingObject(int index) {
    final sizes = [60.0, 100.0, 40.0, 80.0, 120.0, 150.0];
    final opacities = [0.15, 0.1, 0.2, 0.15, 0.08, 0.05];
    return Container(
      width: sizes[index],
      height: sizes[index],
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacities[index]),
        shape: index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: index % 2 == 0 ? null : BorderRadius.circular(20),
      ),
    );
  }
}
