import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

class Mp3ListScreen extends StatelessWidget {
  final Mp3Controller controller = Get.put(Mp3Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("🎧 Your MP3 Collection")),
      body: StreamBuilder(
        stream: controller.audioStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final url = data['url'];

              return Card(
                color: Colors.grey.shade900,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.music_note, color: Colors.white),
                  ),
                  title: Text("MP3 ${index + 1}",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  trailing: Obx(() {
                    final isPlaying = controller.playingIndex.value == index;
                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        size: 30,
                        color: isPlaying ? Colors.greenAccent : Colors.deepPurpleAccent,
                      ),
                      onPressed: () {
                        isPlaying
                            ? controller.stopAudio()
                            : controller.playAudio(url, index);
                      },
                    );
                  }),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
