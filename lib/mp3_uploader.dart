import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//
class Mp3UploaderScreen extends StatefulWidget {
  @override
  State<Mp3UploaderScreen> createState() => _Mp3UploaderScreenState();
}

class _Mp3UploaderScreenState extends State<Mp3UploaderScreen> {
  bool isUploading = false;
  final TextEditingController songName = TextEditingController();
  final TextEditingController artistName = TextEditingController();

  Future<void> pickAndUpload() async {
    if (songName.text.isEmpty || artistName.text.isEmpty) {
      Get.snackbar("Missing Fields", "Please enter song and artist name");
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      Get.snackbar("Cancelled", "No MP3 selected");
      return;
    }

    Uint8List fileBytes = result.files.single.bytes!;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() => isUploading = true);

    try {
      final mp3Snap = await FirebaseStorage.instance
          .ref('audios/$fileName.mp3')
          .putData(fileBytes);
      final mp3Url = await mp3Snap.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('audios').add({
        'url': mp3Url,
        'songName': songName.text.trim(),
        'artistName': artistName.text.trim(),
        'uploadedAt': Timestamp.now(),
      });

      Get.snackbar("Success", "MP3 uploaded successfully!");
    } catch (e) {
      Get.snackbar("Upload Failed", "Reason: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Upload MP3")),
      body: isUploading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 20),
            Text("Uploading...", style: TextStyle(color: Colors.white)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          children: [
            TextField(
              controller: songName,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Song Name",
                hintStyle: TextStyle(color: Colors.white60),
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: artistName,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Artist Name",
                hintStyle: TextStyle(color: Colors.white60),
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.upload),
              label: Text("Upload MP3"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: pickAndUpload,
            ),
          ],
        ),
      ),
    );
  }
}