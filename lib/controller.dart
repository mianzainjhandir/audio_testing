import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// This controller handles AUDIO PLAYBACK and track listing
class Mp3Controller extends GetxController {
  final audioPlayer = AudioPlayer();
  final playingIndex = RxInt(-1); // Initialize to -1 (no track playing)
  final duration = Rx<Duration>(Duration.zero);
  final position = Rx<Duration>(Duration.zero);
  final volume = 1.0.obs;
  final isShuffling = false.obs;
  final allTracks = <Map<String, dynamic>>[].obs; // Use RxList directly
  final currentTrackList = <Map<String, dynamic>>[].obs; // Use RxList directly


  Stream<QuerySnapshot> get audioStream => FirebaseFirestore.instance
      .collection('audios')
      .orderBy('uploadedAt', descending: true)
      .snapshots();

  // Simplified and more efficient way to update tracks
  void updateTracks(List<QueryDocumentSnapshot> docs) {
    // Prevent unnecessary updates if data hasn't changed significantly (optional optimization)
    // List<Map<String, dynamic>> newTracks = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    // if (!listEquals(allTracks, newTracks)) { // Requires foundation import for listEquals
    //   allTracks.value = newTracks;
    //   updateTrackList();
    // }
    allTracks.value = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    updateTrackList(); // Update ordered list whenever source changes
  }

  // Updates the list used for display (handles shuffling)
  void updateTrackList() {
    if (isShuffling.value) {
      // Create a new shuffled list from the source
      currentTrackList.value = allTracks.toList()..shuffle(Random());
    } else {
      // Use the original order
      currentTrackList.value = allTracks.toList();
    }
  }

  // Plays audio at the given index from the currentTrackList
  Future<void> playAudio(String url, int index) async {
    // Optional: Check if the URL is valid before attempting to play
    if (!Uri.tryParse(url)!.isAbsolute ?? true) {
      Get.snackbar("Error", "Invalid audio URL.");
      playingIndex.value = -1; // Ensure state is reset
      return;
    }

    try {
      playingIndex.value = index; // Set playing index immediately for UI feedback
      await audioPlayer.setUrl(url);
      await audioPlayer.setVolume(volume.value);
      await audioPlayer.play();
      // playingIndex.value = index; // Set playing index after successful load/play
    } catch (e) {
      Get.snackbar("Error", "Could not play audio: $e");
      playingIndex.value = -1; // Reset index on error
      // Consider stopping the player explicitly if needed
      // await audioPlayer.stop();
    }
  }

  // Stops the currently playing audio
  Future<void> stopAudio() async {
    try {
      await audioPlayer.stop();
      playingIndex.value = -1; // Reset index
      position.value = Duration.zero; // Reset position
    } catch (e) {
      Get.snackbar("Error", "Could not stop audio: $e");
    }
  }

  // Sets the player volume
  void setVolume(double value) {
    volume.value = value.clamp(0.0, 1.0); // Ensure volume is within valid range
    audioPlayer.setVolume(volume.value);
  }

  // Seeks to a specific position in the audio
  void seek(Duration position) {
    // Check if duration is available before seeking
    if (duration.value > Duration.zero) {
      audioPlayer.seek(position);
    }
  }

  // Toggle shuffle mode
  void toggleShuffle() {
    isShuffling.value = !isShuffling.value;
    updateTrackList(); // Reorder the list when shuffle changes
    Get.snackbar("Shuffle", isShuffling.value ? "Shuffle On" : "Shuffle Off", duration: Duration(seconds: 1));
  }


  @override
  void onInit() {
    super.onInit();
    // Listen to player state changes (e.g., completed)
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Optional: Implement auto-play next track logic here
        print("Track completed");
        stopAudio(); // Or playNext();
      }
    });

    // Listen to duration changes
    audioPlayer.durationStream.listen((d) {
      duration.value = d ?? Duration.zero;
    });

    // Listen to position changes
    audioPlayer.positionStream.listen((p) {
      // Only update position if duration is known and positive
      if (duration.value > Duration.zero) {
        position.value = p;
      }
    });
  }

  @override
  void onClose() {
    audioPlayer.dispose(); // Dispose the player when controller is closed
    super.onClose();
  }
}