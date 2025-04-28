import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';
import 'controller.dart';

class Mp3ListScreen extends StatefulWidget {
  const Mp3ListScreen({Key? key}) : super(key: key);

  @override
  State<Mp3ListScreen> createState() => _Mp3ListScreenState();
}

class _Mp3ListScreenState extends State<Mp3ListScreen>
    with TickerProviderStateMixin {
  final Mp3Controller controller = Get.put(Mp3Controller());

  // Format time (Duration) to show in "mm:ss" format
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Colors.deepPurple,
            spawnOpacity: 0.1,
            opacityChangeRate: 0.25,
            minOpacity: 0.2,
            maxOpacity: 0.7,
            particleCount: 50,
            spawnMaxRadius: 15.0,
            spawnMinRadius: 10.0,
            spawnMaxSpeed: 40.0,
            spawnMinSpeed: 10.0,
          ),
        ),
        vsync: this,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.grey[900],
                title: const Text(
                  "🎧 MP3 Studio",
                  style: TextStyle(color: Colors.white),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: Obx(
                      () => Icon(
                        controller.isShuffling.value
                            ? Icons.shuffle_rounded
                            : Icons.shuffle,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: controller.toggleShuffle,
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder(
                  stream: controller.audioStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final url = data['url'];
                        final img = data['image'] ?? "";
                        final title = data['songName'] ?? "Unknown Song";
                        final artist = data['artistName'] ?? "Unknown Artist";

                        return Obx(() {
                          final isPlaying =
                              controller.playingIndex.value == index;

                          return Card(
                            color:
                                isPlaying
                                    ? Colors.deepPurple.withAlpha(40)
                                    : Colors.grey.shade900,
                            elevation: isPlaying ? 6 : 4,
                            shadowColor:
                                isPlaying
                                    ? Colors.deepPurpleAccent.withAlpha(50)
                                    : Colors.black.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  isPlaying
                                      ? const BorderSide(
                                        color: Colors.deepPurpleAccent,
                                        width: 1,
                                      )
                                      : BorderSide.none,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade800,
                                      child:
                                          img.isNotEmpty
                                              ? Image.network(
                                                img,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.white54,
                                                    ),
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return const Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          Colors
                                                              .deepPurpleAccent,
                                                    ),
                                                  );
                                                },
                                              )
                                              : const Icon(
                                                Icons.music_note_rounded,
                                                size: 30,
                                                color: Colors.white70,
                                              ),
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    artist,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      size: 42,
                                      color:
                                          isPlaying
                                              ? Colors.greenAccent.shade400
                                              : Colors.deepPurpleAccent,
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: SliderTheme(
                                            data: SliderTheme.of(
                                              context,
                                            ).copyWith(
                                              trackHeight: 3,
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                    enabledThumbRadius: 7,
                                                  ),
                                              activeTrackColor:
                                                  Colors.redAccent,
                                              inactiveTrackColor:
                                                  Colors.grey.shade700,
                                              thumbColor: Colors.redAccent,
                                            ),
                                            child: Slider(
                                              min: 0,
                                              max:
                                                  dur.inMilliseconds.toDouble(),
                                              value:
                                                  pos.inMilliseconds
                                                      .clamp(
                                                        0,
                                                        dur.inMilliseconds,
                                                      )
                                                      .toDouble(),
                                              onChanged: (value) {
                                                controller.audioPlayer.seek(
                                                  Duration(
                                                    milliseconds: value.toInt(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(pos),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(dur),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.stop_rounded,
                                                  color: Colors.white70,
                                                  size: 40,
                                                ),
                                                onPressed: controller.stopAudio,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Equalizer Controls
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Bass',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  Slider(
                                                    min: 0,
                                                    max: 1,
                                                    value:
                                                        controller.bass.value,
                                                    onChanged:
                                                        controller.updateBass,
                                                    activeColor:
                                                        Colors.greenAccent,
                                                    inactiveColor:
                                                        Colors.white30,
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Mid',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  Slider(
                                                    min: 0,
                                                    max: 1,
                                                    value: controller.mid.value,
                                                    onChanged:
                                                        controller.updateMid,
                                                    activeColor:
                                                        Colors.greenAccent,
                                                    inactiveColor:
                                                        Colors.white30,
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Treble',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  Slider(
                                                    min: 0,
                                                    max: 1,
                                                    value:
                                                        controller.treble.value,
                                                    onChanged:
                                                        controller.updateTreble,
                                                    activeColor:
                                                        Colors.greenAccent,
                                                    inactiveColor:
                                                        Colors.white30,
                                                  ),
                                                ],
                                              ),
                                              // Sleep Timer Dropdown
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      "Sleep Timer: ",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    DropdownButton<int>(
                                                      dropdownColor:
                                                          Colors.black,
                                                      value:
                                                          controller
                                                              .timerDuration
                                                              .value,
                                                      items: List.generate(6, (
                                                        index,
                                                      ) {
                                                        return DropdownMenuItem(
                                                          value:
                                                              (index + 1) * 5,
                                                          child: Text(
                                                            "${(index + 1) * 5} min",
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                        );
                                                      }),
                                                      onChanged: (
                                                        int? newValue,
                                                      ) {
                                                        if (newValue != null)
                                                          controller
                                                              .updateSleepTimer(
                                                                newValue,
                                                              );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ],
                            ),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
