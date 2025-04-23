// controller.dart
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class Mp3Controller extends GetxController {
  final audioPlayer = AudioPlayer();
  final playingIndex = RxnInt();
  final duration = Rx<Duration>(Duration.zero);
  final position = Rx<Duration>(Duration.zero);
  final volume = 1.0.obs;
  final isShuffling = false.obs;
  final List<Map<String, dynamic>> allTracks = [];
  final RxList<Map<String, dynamic>> currentTrackList = <Map<String, dynamic>>[].obs;

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

  Future<void> playPrevious() async {
    if (currentTrackList.isEmpty || playingIndex.value == null) return;
    int prevIndex = (playingIndex.value! - 1 + currentTrackList.length) % currentTrackList.length;
    final prevTrack = currentTrackList[prevIndex];
    await playAudio(prevTrack['url'], prevIndex);
  }

  void seekTo(Duration position) {
    audioPlayer.seek(position);
  }

  void toggleShuffle() {
    isShuffling.value = !isShuffling.value;
    updateTrackList();
    if (playingIndex.value != null) {
      final currentTrack = currentTrackList[playingIndex.value!];
      int newIndex = currentTrackList.indexOf(currentTrack);
      playingIndex.value = newIndex;
    }
  }

  @override
  void onInit() {
    super.onInit();
    audioPlayer.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });
    audioPlayer.positionStream.listen((p) {
      position.value = p;
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
    super.onClose();
  }
}
