import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Mp3UploaderScreen extends StatefulWidget {
  @override
  State<Mp3UploaderScreen> createState() => _Mp3UploaderScreenState();
}

class _Mp3UploaderScreenState extends State<Mp3UploaderScreen> {
  bool isUploading = false;

  Future<void> pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      withData: true,
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.single.bytes;
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() => isUploading = true);

      try {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref('audios/$fileName.mp3')
            .putData(fileBytes!);

        TaskSnapshot snap = await uploadTask;
        String url = await snap.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('audios').add({
          'url': url,
          'uploadedAt': Timestamp.now(),
        });

        Get.snackbar("Uploaded", "MP3 uploaded successfully!");
      } catch (e) {
        Get.snackbar("Error", "Upload failed.");
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Upload MP3")),
      body: Center(
        child: isUploading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 20),
            Text("Uploading...", style: TextStyle(fontSize: 16)),
          ],
        )
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.cloud_upload_outlined),
            label: Text("Select & Upload MP3", style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: pickAndUpload,
          ),
        ),
      ),
    );
  }
}
