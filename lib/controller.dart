import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mp3Controller extends GetxController {
  final audioPlayer = AudioPlayer();
  final playingIndex = RxnInt();

  Stream<QuerySnapshot> get audioStream => FirebaseFirestore.instance
      .collection('audios')
      .orderBy('uploadedAt', descending: true)
      .snapshots();

  Future<void> playAudio(String url, int index) async {
    try {
      await audioPlayer.setUrl(url);
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

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }
}
