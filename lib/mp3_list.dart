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
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text("🎧 Your MP3 Collection", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: controller.audioStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));

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

              return Obx(() {
                final isPlaying = controller.playingIndex.value == index;

                return Card(
                  color: isPlaying ? Colors.deepPurple.withAlpha(40) : Colors.grey.shade900,
                  elevation: isPlaying ? 6 : 4,
                  shadowColor: isPlaying ? Colors.deepPurpleAccent.withAlpha(50) : Colors.black.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isPlaying ? BorderSide(color: Colors.deepPurpleAccent, width: 1) : BorderSide.none,
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade800,
                            child: img.isNotEmpty
                                ? Image.network(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, color: Colors.white54),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent));
                              },
                            )
                                : Icon(Icons.music_note_rounded, size: 30, color: Colors.white70),
                          ),
                        ),
                        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(artist, style: TextStyle(color: Colors.white60)),
                        trailing: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            size: 42,
                            color: isPlaying ? Colors.greenAccent.shade400 : Colors.deepPurpleAccent,
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                                    activeTrackColor: Colors.redAccent,
                                    inactiveTrackColor: Colors.grey.shade700,
                                    thumbColor: Colors.redAccent,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: dur.inMilliseconds.toDouble(),
                                    value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                                    onChanged: (value) {
                                      controller.audioPlayer.seek(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(pos), style: TextStyle(color: Colors.white70)),
                                    Text(_formatDuration(dur), style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Volume", style: TextStyle(color: Colors.white70)),
                                    Obx(() => SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2,
                                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                        activeTrackColor: Colors.blueAccent.shade100,
                                        inactiveTrackColor: Colors.grey.shade600,
                                        thumbColor: Colors.blueAccent.shade100,
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: 1,
                                        value: controller.volume.value,
                                        onChanged: controller.setVolume,
                                      ),
                                    )),
                                  ],
                                ),
                              )
                            ],
                          );
                        })
                      ]//
                    ],
                  ),
                );
              });
            },
          );
        },
      ),
    );
  }
}
