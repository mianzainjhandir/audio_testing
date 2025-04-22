import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for QuerySnapshot
import 'controller.dart'; // Your Mp3Controller file

class Mp3ListScreen extends StatelessWidget {
  // Inject the Mp3Controller. GetX handles creating/finding the instance.
  final Mp3Controller controller = Get.put(Mp3Controller());

  Mp3ListScreen({super.key}); // Add super key

  // Helper function to format duration (e.g., 01:30)
  String _formatDuration(Duration duration) {
    // Handle potential negative durations defensively
    duration = duration.isNegative ? Duration.zero : duration;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) { // context is available here
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("\uD83C\uDFA7 Your MP3 Collection", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white), // Back arrow color
        actions: [
          // Shuffle Toggle Button
          Obx(() => IconButton(
            icon: Icon(
              controller.isShuffling.value ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
              color: controller.isShuffling.value ? Colors.deepPurpleAccent : Colors.white70,
            ),
            tooltip: 'Toggle Shuffle',
            onPressed: controller.toggleShuffle, // Call controller method
          )),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.audioStream, // Get stream from Mp3Controller
        builder: (context, snapshot) { // context is available here too
          // --- Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
          }

          // --- Handle Error State ---
          if (snapshot.hasError) {
            print("Firestore Error: ${snapshot.error}"); // Log error
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error loading tracks.\nPlease check your connection or Firebase setup.\n(${snapshot.error.toString().split(']').last.trim()})", // Show concise error
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            );
          }

          // --- Handle No Data State ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column( // Use column for icon + text
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music_outlined, size: 60, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    "Your collection is empty.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Go back and upload some tracks!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // --- Data Received: Update Controller and Build List ---
          controller.updateTracks(snapshot.data!.docs);

          // Use Obx to reactively rebuild the ListView when controller.currentTrackList changes
          return Obx(() {
            if (controller.currentTrackList.isEmpty) {
              return Center(child: Text("No tracks match current view.", style: TextStyle(color: Colors.white54)));
            }
            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              itemCount: controller.currentTrackList.length,
              itemBuilder: (context, index) { // context is available in itemBuilder
                if (index >= controller.currentTrackList.length) {
                  return SizedBox.shrink();
                }
                final data = controller.currentTrackList[index];
                final String url = data['url'] as String? ?? '';
                final String img = data['image'] as String? ?? '';
                final String title = data['songName'] as String? ?? 'Unknown Song';
                final String artist = data['artistName'] as String? ?? 'Unknown Artist';

                // Use Obx for widgets that depend on the *playback state* of this specific item
                return Obx(() {
                  final isPlaying = controller.playingIndex.value == index;
                  return Card(
                    color: isPlaying ? Colors.deepPurple.withAlpha(40) : Colors.grey.shade900,
                    elevation: isPlaying ? 6 : 4,
                    shadowColor: isPlaying ? Colors.deepPurpleAccent.withAlpha(50) : Colors.black.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isPlaying ? BorderSide(color: Colors.deepPurpleAccent.withAlpha(100), width: 1) : BorderSide.none,
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.only(left: 16.0, right: 8.0, top: 10.0, bottom: isPlaying ? 0 : 10.0),
                          leading: _buildLeadingImage(img),
                          title: Text(
                            title,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            artist,
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: _buildPlayPauseButton(controller, url, index, isPlaying),
                        ),
                        // Conditionally show player controls only for the playing item
                        if (isPlaying)
                        // **** CORRECTION: Pass context here ****
                          _buildPlayerControls(context, controller),
                      ],
                    ),
                  );
                });
              },
            );
          });
        },
      ),
    );
  }

  // --- Helper Widgets for Readability ---

  Widget _buildLeadingImage(String imgUrl) {
    // ... (no changes needed in this method)
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 50,
        height: 50,
        color: Colors.grey.shade800, // Background color
        child: imgUrl.isNotEmpty
            ? Image.network(
          imgUrl,
          fit: BoxFit.cover,
          // Add better loading and error handling
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image_outlined, size: 30, color: Colors.white60),
        )
            : Icon(Icons.music_note_rounded, size: 30, color: Colors.white70), // Placeholder icon
      ),
    );
  }

  Widget _buildPlayPauseButton(Mp3Controller controller, String url, int index, bool isPlaying) {
    // ... (no changes needed in this method)
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
        size: 42, // Slightly larger button
        color: isPlaying ? Colors.greenAccent.shade400 : Colors.deepPurpleAccent,
      ),
      padding: EdgeInsets.zero, // Remove default padding
      visualDensity: VisualDensity.compact, // Make it tighter
      tooltip: isPlaying ? 'Pause' : 'Play',
      // Disable button if URL is empty
      onPressed: url.isNotEmpty
          ? () {
        isPlaying
            ? controller.stopAudio()
            : controller.playAudio(url, index);
      }
          : () { Get.snackbar("Info", "Audio URL is missing for this track."); }, // Feedback if disabled
    );
  }

  // **** CORRECTION: Add BuildContext context parameter ****
  Widget _buildPlayerControls(BuildContext context, Mp3Controller controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0, top: 0),
      child: Column(
        children: [
          // --- Progress Slider and Time ---
          Obx(() {
            final position = controller.position.value;
            final duration = controller.duration.value;
            final maxDuration = (duration.inMilliseconds > 0) ? duration.inMilliseconds.toDouble() : 1.0;
            final currentPosition = position.inMilliseconds.clamp(0.0, maxDuration).toDouble();
            final bool canSeek = duration > Duration.zero;

            return Column(
              children: [
                SliderTheme(
                  // **** Use the passed context ****
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
                    activeTrackColor: Colors.redAccent.shade400,
                    inactiveTrackColor: Colors.grey.shade700,
                    thumbColor: Colors.redAccent.shade400,
                    overlayColor: Colors.redAccent.withAlpha(60),
                    disabledActiveTrackColor: Colors.grey.shade600,
                    disabledInactiveTrackColor: Colors.grey.shade800,
                    disabledThumbColor: Colors.grey.shade600,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxDuration,
                    value: currentPosition,
                    onChanged: canSeek ? (value) {
                      controller.seek(Duration(milliseconds: value.toInt()));
                    } : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(_formatDuration(duration), style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: 4),

          // --- Volume Slider ---
          Row(
            children: [
              Icon(Icons.volume_mute_rounded, color: Colors.white60, size: 18),
              Expanded(
                child: Obx(() => SliderTheme(
                  // **** Use the passed context ****
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                    activeTrackColor: Colors.blueAccent.shade100,
                    inactiveTrackColor: Colors.grey.shade600,
                    thumbColor: Colors.blueAccent.shade100,
                    overlayColor: Colors.blueAccent.withAlpha(50),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    value: controller.volume.value,
                    onChanged: controller.setVolume,
                  ),
                )),
              ),
              Icon(Icons.volume_up_rounded, color: Colors.white60, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}