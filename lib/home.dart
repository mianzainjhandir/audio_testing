import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart'; // Import animated_background
import 'package:animate_do/animate_do.dart'; // Import animate_do
import 'mp3_list.dart';
import 'mp3_uploader.dart';

// Make it stateful to use TickerProvider for AnimatedBackground
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin { // Add TickerProviderStateMixin
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use AnimatedBackground instead of Container with gradient
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour( // Use particle effect
          options: const ParticleOptions(
            baseColor: Colors.deepPurple, // Base color for particles
            spawnOpacity: 0.1,
            opacityChangeRate: 0.25,
            minOpacity: 0.2,
            maxOpacity: 0.7,
            particleCount: 50, // Adjust particle count
            spawnMaxRadius: 15.0,
            spawnMinRadius: 10.0,
            spawnMaxSpeed: 40.0,
            spawnMinSpeed: 10.0,
          ),
          paint: Paint()..style=PaintingStyle.fill..strokeWidth=1.0, // Customize particle paint if needed
        ),
        // behaviour: RacingLinesBehaviour(direction: LineDirection.Ltr, numLines: 30), // Alternative: Racing lines
        vsync: this, // Provide the TickerProvider
        child: Container(
          // Add a semi-transparent overlay if particles make text hard to read
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Animated Title ---
                  FadeInDown( // Animate title fading down
                    duration: const Duration(milliseconds: 800),
                    child: ShaderMask( // Apply gradient to text
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.deepPurpleAccent.shade100, Colors.purpleAccent.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "\uD83C\uDFB5 MP3 Studio",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36, // Slightly larger font
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Base color (will be masked by gradient)
                          shadows: [ // Add a subtle shadow
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.5),
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60), // Increased spacing

                  // --- Animated Upload Button ---
                  FadeInUp( // Animate button fading up
                    delay: const Duration(milliseconds: 300), // Delay slightly
                    duration: const Duration(milliseconds: 700),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.cloud_upload_rounded, size: 26), // Slightly different icon
                      label: Text("Upload MP3"),
                      onPressed: () => Get.to(() => Mp3UploaderScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white, // Text and icon color
                        padding: EdgeInsets.symmetric(vertical: 18), // Increased padding
                        textStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // More rounded
                        elevation: 8, // Add elevation
                        shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 25), // Increased spacing

                  // --- Animated Play Button ---
                  FadeInUp( // Animate button fading up
                    delay: const Duration(milliseconds: 500), // Delay more
                    duration: const Duration(milliseconds: 700),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.play_circle_outline_rounded, size: 26), // Slightly different icon
                      label: Text("Play MP3s"),
                      onPressed: () => Get.to(() => Mp3ListScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
                        foregroundColor: Colors.white, // Text and icon color
                        padding: EdgeInsets.symmetric(vertical: 18),
                        textStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 8,
                        shadowColor: Colors.deepPurple.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}