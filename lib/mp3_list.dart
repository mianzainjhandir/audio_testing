// mp3_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class Mp3ListScreen extends StatelessWidget {
  final Mp3Controller controller = Get.put(Mp3Controller());

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("\uD83C\uDFA7 Your MP3 Collection")),
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
              final img = data['image'] ?? "";
              final title = data['songName'] ?? "Unknown Song";
              final artist = data['artistName'] ?? "Unknown Artist";

              return Card(
                color: Colors.grey.shade900,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Obx(() {
                  final isPlaying = controller.playingIndex.value == index;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: img.isNotEmpty
                            ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(img, width: 50, height: 50, fit: BoxFit.cover))
                            : Icon(Icons.music_note, size: 40, color: Colors.white70),
                        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(artist, style: TextStyle(color: Colors.white60)),
                        trailing: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            size: 34,
                            color: isPlaying ? Colors.greenAccent : Colors.deepPurpleAccent,
                          ),
                          onPressed: () {
                            isPlaying
                                ? controller.stopAudio()
                                : controller.playAudio(url, index);
                          },
                        ),
                      ),
                      if (isPlaying) ...[
                        Obx(() {
                          final pos = controller.position.value;
                          final dur = controller.duration.value;
                          return Column(
                            children: [
                              Slider(
                                min: 0,
                                max: dur.inMilliseconds.toDouble(),
                                value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                                onChanged: (value) {
                                  controller.audioPlayer
                                      .seek(Duration(milliseconds: value.toInt()));
                                },
                                activeColor: Colors.redAccent,
                                inactiveColor: Colors.grey.shade700,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(pos),
                                        style: TextStyle(color: Colors.white70)),
                                    Text(_formatDuration(dur),
                                        style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Volume", style: TextStyle(color: Colors.white70)),
                                    Obx(() => Slider(
                                      min: 0,
                                      max: 1,
                                      value: controller.volume.value,
                                      onChanged: controller.setVolume,
                                      activeColor: Colors.deepPurpleAccent,
                                      inactiveColor: Colors.grey,
                                    )),
                                  ],
                                ),
                              )
                            ],
                          );
                        })
                      ]
                    ],
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }
}