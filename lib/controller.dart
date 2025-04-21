
// controller.dart
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mp3Controller extends GetxController {
  final audioPlayer = AudioPlayer();
  final playingIndex = RxnInt();
  final duration = Rx<Duration>(Duration.zero);
  final position = Rx<Duration>(Duration.zero);
  final volume = 1.0.obs;

  Stream<QuerySnapshot> get audioStream => FirebaseFirestore.instance
      .collection('audios')
      .orderBy('uploadedAt', descending: true)
      .snapshots();

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

  @override
  void onInit() {
    super.onInit();
    audioPlayer.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });
    audioPlayer.positionStream.listen((p) {
      position.value = p;
    });
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }
}
