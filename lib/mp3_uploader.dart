import 'dart:convert';
import 'dart:html' as html; // For browser native file picking
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart'; // For picking MP3
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- GetX Controller for Upload Logic ---
class UploadController extends GetxController {
  final RxBool isUploading = false.obs;
  // Use RxnString for nullable reactive string
  final RxnString imageUrl = RxnString();

  // Helper to sanitize filenames
  String _sanitizeFileName(String fileName) {
    // Replace characters invalid in Firebase Storage paths
    return fileName.replaceAll(RegExp(r'[#\[\]*?/]'), '_');
  }

  // Pick image using browser's input element
  Future<void> pickImage() async {
    final filePicker = html.FileUploadInputElement()..accept = 'image/*';
    filePicker.click();

    filePicker.onChange.listen((event) {
      final files = filePicker.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          imageUrl.value = reader.result as String?;
        });
      } else {
        Get.snackbar("Info", "No image file selected.");
        imageUrl.value = null; // Clear if no file selected
      }
    });
  }

  // Pick MP3 and upload both files
  Future<void> pickAndUpload(String songName, String artistName) async {
    // Basic validation
    if (songName.trim().isEmpty) {
      Get.snackbar("Error", "Please enter a song name.");
      return;
    }
    if (artistName.trim().isEmpty) {
      Get.snackbar("Error", "Please enter an artist name.");
      return;
    }
    if (imageUrl.value == null) {
      Get.snackbar("Error", "Please choose an image.");
      return;
    }

    // Pick MP3 file
    FilePickerResult? mp3Result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      withData: true, // Ensure bytes are loaded
    );

    if (mp3Result == null || mp3Result.files.isEmpty || mp3Result.files.first.bytes == null) {
      Get.snackbar("Error", "No valid MP3 file selected.");
      return;
    }

    isUploading.value = true;

    try {
      // --- MP3 Upload ---
      final mp3File = mp3Result.files.first;
      final mp3Bytes = mp3File.bytes!;
      // Use timestamp and sanitized original name for uniqueness
      final mp3FileName = '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(mp3File.name)}';
      final mp3Ref = FirebaseStorage.instance.ref('audios/$mp3FileName');
      final mp3UploadTask = await mp3Ref.putData(mp3Bytes);
      final mp3DownloadUrl = await mp3UploadTask.ref.getDownloadURL();

      // --- Image Upload ---
      // Decode Base64 data URL
      final String base64Data = imageUrl.value!.substring(imageUrl.value!.indexOf(',') + 1);
      final Uint8List imageBytes = base64Decode(base64Data);
      // Create a reasonable image filename (e.g., based on song name or timestamp)
      final imageFileName = '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(songName)}.png'; // Assume png for simplicity
      final imageRef = FirebaseStorage.instance.ref('images/$imageFileName');
      final imageUploadTask = await imageRef.putData(imageBytes);
      final imageDownloadUrl = await imageUploadTask.ref.getDownloadURL(); // Get final image URL

      // --- Save to Firestore ---
      await FirebaseFirestore.instance.collection('audios').add({
        'url': mp3DownloadUrl,
        'image': imageDownloadUrl, // Save the actual download URL
        'songName': songName.trim(),
        'artistName': artistName.trim(),
        'uploadedAt': Timestamp.now(),
      });

      Get.snackbar("Success", "Upload complete!");
      // Reset state and navigate back
      imageUrl.value = null;
      Get.offAllNamed('/'); // Navigate back to home, clearing stack

    } on FirebaseException catch (e) {
      Get.snackbar("Firebase Error", "Upload failed: ${e.message} (Code: ${e.code})");
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e");
    } finally {
      isUploading.value = false;
    }
  }
}

// --- UI Screen ---
class Mp3UploaderScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final songNameController = TextEditingController();
  final artistNameController = TextEditingController();
  // Inject the controller
  final UploadController controller = Get.put(UploadController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Upload MP3", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white), // Back button color
      ),
      body: Obx(() { // Use Obx to react to isUploading state
        return controller.isUploading.value
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepPurpleAccent),
              SizedBox(height: 20),
              Text("Uploading...", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons full width
              children: [
                TextFormField(
                  controller: songNameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Song Name",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter song name' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: artistNameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Artist Name",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter artist name' : null,
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: Icon(Icons.image_outlined),
                  label: Text("Choose Cover Image"),
                  onPressed: () => controller.pickImage(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 20),
                // Use Obx for the image preview based on controller's imageUrl
                Obx(() {
                  final url = controller.imageUrl.value;
                  if (url != null) {
                    try {
                      // Decode base64 image for preview
                      final imageBytes = base64Decode(url.substring(url.indexOf(',') + 1));
                      return Center( // Center the preview
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            imageBytes,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.red, size: 50),
                          ),
                        ),
                      );//
                    } catch (e) {
                      // Handle potential decoding errors
                      return Center(child: Text('Invalid image data', style: TextStyle(color: Colors.red)));
                    }
                  } else {
                    return SizedBox.shrink(); // Show nothing if no image is selected
                  }
                }),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: Icon(Icons.upload_file),
                  label: Text("Upload MP3 & Image"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      controller.pickAndUpload(
                          songNameController.text,
                          artistNameController.text
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      ),
    );
  }
}