// controller.dart (UPDATED)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import 'package:flutter_fft/flutter_fft.dart'; // << Add this import
import 'dart:math';

class Mp3Controller extends GetxController {
  final audioPlayer = AudioPlayer();
  final playingIndex = RxnInt();
  final duration = Rx<Duration>(Duration.zero);
  final position = Rx<Duration>(Duration.zero);
  final volume = 1.0.obs;
  final isShuffling = false.obs;
  final bass = 0.10.obs;
  final mid = 0.5.obs;
  final treble = 0.5.obs;
  final timerDuration = 5.obs;
  final List<Map<String, dynamic>> allTracks = [];
  final RxList<Map<String, dynamic>> currentTrackList = <Map<String, dynamic>>[].obs;

  // 🔥 Flutter FFT (Pitch detection)
  final FlutterFft flutterFft = FlutterFft();
  final RxBool isRecording = false.obs;
  final RxDouble detectedFrequency = 0.0.obs;
  final RxString detectedNote = ''.obs;

  Stream<QuerySnapshot> get audioStream => FirebaseFirestore.instance
      .collection('audios')
      .orderBy('uploadedAt', descending: true)
      .snapshots();

  void setTracks(List<QueryDocumentSnapshot> docs) {
    allTracks.clear();
    for (var doc in docs) {
      allTracks.add(doc.data() as Map<String, dynamic>);
    }
    updateTrackList();
  }

  void updateTrackList() {
    if (isShuffling.value) {
      final shuffled = [...allTracks]..shuffle(Random());
      currentTrackList.value = shuffled;
    } else {
      currentTrackList.value = [...allTracks];
    }
  }

  Future<void> playAudio(String url, int index) async {
    try {
      await audioPlayer.setUrl(url);
      await audioPlayer.setVolume(volume.value);
      await audioPlayer.play();
      playingIndex.value = index;
    } catch (e) {
      Get.snackbar("Error", "Could not play audio");
    }
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    playingIndex.value = null;
  }

  void setVolume(double value) {
    volume.value = value;
    audioPlayer.setVolume(value);
  }

  Future<void> playNext() async {
    if (currentTrackList.isEmpty || playingIndex.value == null) return;
    int nextIndex = (playingIndex.value! + 1) % currentTrackList.length;
    final nextTrack = currentTrackList[nextIndex];
    await playAudio(nextTrack['url'], nextIndex);
  }

  void updateBass(double value) {
    bass.value = value;
  }

  void updateMid(double value) {
    mid.value = value;
  }

  void updateTreble(double value) {
    treble.value = value;
  }

  void updateSleepTimer(int value) {
    timerDuration.value = value;
  }

  void toggleShuffle() {
    isShuffling.value = !isShuffling.value;
    updateTrackList();
  }

  // 🔥 Start FFT listening
  Future<void> startListening() async {
    try {
      await flutterFft.startRecorder();
      isRecording.value = true;

      flutterFft.onRecorderStateChanged.listen((data) {
        detectedFrequency.value = (data[1] as double?) ?? 0.0;
        detectedNote.value = (data[2] as String?) ?? '';
      });

    } catch (e) {
      Get.snackbar("Error", "Could not start FFT recorder");
    }
  }

  Future<void> stopListening() async {
    try {
      await flutterFft.stopRecorder();
      isRecording.value = false;
    } catch (e) {
      Get.snackbar("Error", "Could not stop FFT recorder");
    }
  }

  @override
  void onInit() {
    super.onInit();
    audioPlayer.positionStream.listen((p) {
      position.value = p;
    });
    audioPlayer.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    flutterFft.stopRecorder();
    super.onClose();
  }
}
