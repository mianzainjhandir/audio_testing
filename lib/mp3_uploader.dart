import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart'; // For picking MP3
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Use image_picker

// --- GetX Controller for Upload Logic ---
class UploadController extends GetxController {
  // --- State Properties ---
  final RxBool isUploading = false.obs;
  final Rxn<Uint8List> imageDataBytes = Rxn<Uint8List>(); // Store image bytes
  final RxnString pickedImageName = RxnString(); // Optional: store filename

  // --- TextEditingControllers ---
  final songNameController = TextEditingController();
  final artistNameController = TextEditingController();

  // --- Services ---
  final ImagePicker _picker = ImagePicker();

  // --- Helper Methods ---
  String _sanitizeFileName(String fileName) {
    String sanitized = fileName.replaceAll(RegExp(r'[#\[\]*?/\\~]'), '_');
    return sanitized.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  // --- Lifecycle Methods ---
  @override
  void onClose() {
    songNameController.dispose();
    artistNameController.dispose();
    if (kDebugMode) print("UploadController disposed");
    super.onClose();
  }

  // --- Core Logic Methods ---
  Future<void> pickImage() async {
    if (isUploading.value) {
      Get.snackbar("Busy", "Please wait for the current upload to finish.");
      return;
    }
    if (kDebugMode) print("Attempting to pick image using image_picker...");
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kDebugMode) print("Image picked: ${pickedFile.name}, mimeType: ${pickedFile.mimeType}");
        imageDataBytes.value = await pickedFile.readAsBytes();
        pickedImageName.value = pickedFile.name;
        if (kDebugMode) print("Image bytes stored in controller (${imageDataBytes.value?.lengthInBytes} bytes).");
      } else {
        if (kDebugMode) print("Image picking cancelled by user.");
      }
    } catch (e) {
      if (kDebugMode) print("Error picking image with image_picker: $e");
      String errorMessage = "Could not pick image: $e";
      if (e.toString().toLowerCase().contains('permission')) {
        errorMessage = "Permission denied to access gallery.";
      }
      Get.snackbar("Image Picker Error", errorMessage);
      imageDataBytes.value = null;
      pickedImageName.value = null;
    }
  }

  Future<void> pickAndUpload() async { // Reads from internal controllers
    if (isUploading.value) {
      Get.snackbar("Busy", "An upload is already in progress.");
      return;
    }

    final String songName = songNameController.text;
    final String artistName = artistNameController.text;

    if (songName.trim().isEmpty || artistName.trim().isEmpty || imageDataBytes.value == null) {
      Get.snackbar("Input Error", "Please fill all fields and select an image.");
      return;
    }

    FilePickerResult? mp3Result;
    try {
      mp3Result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['mp3'], withData: true);
    } catch (e) {
      Get.snackbar("File Picker Error", "Could not pick MP3 file: $e"); return;
    }

    if (mp3Result == null || mp3Result.files.isEmpty || mp3Result.files.first.bytes == null) {
      Get.snackbar("Input Error", "No valid MP3 file selected or data missing."); return;
    }

    isUploading.value = true;
    String? finalMp3Url;
    String? finalImageUrl;

    try {
      // MP3 Upload
      final mp3File = mp3Result.files.first;
      final mp3Bytes = mp3File.bytes!;
      final mp3FileName = '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(mp3File.name)}';
      final mp3Ref = FirebaseStorage.instance.ref('audios/$mp3FileName');
      if (kDebugMode) print("Uploading MP3 (${mp3Bytes.lengthInBytes} bytes) to: ${mp3Ref.fullPath}");
      final mp3UploadTask = await mp3Ref.putData(mp3Bytes, SettableMetadata(contentType: 'audio/mpeg'));
      finalMp3Url = await mp3UploadTask.ref.getDownloadURL();
      if (kDebugMode) print("MP3 Upload successful: $finalMp3Url");

      // Image Upload
      final Uint8List imageBytes = imageDataBytes.value!;
      String imageExtension = 'jpg';
      if (pickedImageName.value?.contains('.') == true) {
        String potentialExtension = pickedImageName.value!.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(potentialExtension)) {
          imageExtension = _sanitizeFileName(potentialExtension);
        }
      }
      final imageFileName = '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(songName)}.$imageExtension';
      final imageRef = FirebaseStorage.instance.ref('images/$imageFileName');
      if (kDebugMode) print("Uploading Image (${imageBytes.lengthInBytes} bytes) to: ${imageRef.fullPath}");
      final imageUploadTask = await imageRef.putData(imageBytes, SettableMetadata(contentType: 'image/$imageExtension'));
      finalImageUrl = await imageUploadTask.ref.getDownloadURL();
      if (kDebugMode) print("Image Upload successful: $finalImageUrl");

      // Save to Firestore
      if (kDebugMode) print("Saving track metadata to Firestore...");
      await FirebaseFirestore.instance.collection('audios').add({
        'url': finalMp3Url, 'image': finalImageUrl,
        'songName': songName.trim(), 'artistName': artistName.trim(),
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print("Firestore save successful.");

      Get.snackbar( "Success", "Track '$songName' uploaded successfully!",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);

      // Reset State
      imageDataBytes.value = null;
      pickedImageName.value = null;
      songNameController.clear();
      artistNameController.clear();
      Get.offAllNamed('/'); // Navigate back

    } on FirebaseException catch (e) {
      String errorMessage = e.message ?? 'An unknown Firebase error.';
      // Add more specific error codes if needed
      if (e.code == 'permission-denied') errorMessage = 'Permission denied. Check Firebase rules.';
      Get.snackbar( "Firebase Error", "Upload failed: $errorMessage (Code: ${e.code})",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      if (kDebugMode) print("Firebase Error during upload/save: ${e.toString()}");
    } catch (e, s) {
      Get.snackbar( "Error", "An unexpected error occurred: $e",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      if (kDebugMode) { print("Unexpected Upload Error: $e"); print("Stack Trace: $s"); }
    } finally {
      isUploading.value = false; // Ensure loading state is always reset
    }
  }
}

// --- UI Screen ---
class Mp3UploaderScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  // Inject the controller. GetX manages its lifecycle (creation and disposal).
  final UploadController controller = Get.put(UploadController());

  Mp3UploaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Upload MP3", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Obx(() { // Use Obx for reactive UI updates
        return controller.isUploading.value
        // --- Loading Indicator ---
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepPurpleAccent),
              SizedBox(height: 20),
              Text("Uploading, please wait...", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        )
        // --- Upload Form ---
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Song Name Input ---
                TextFormField(
                  // Use controller from GetX instance
                  controller: controller.songNameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Song Name",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade600)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                    errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                    focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent, width: 2)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter song name' : null,
                ),
                SizedBox(height: 16),

                // --- Artist Name Input ---
                TextFormField(
                  // Use controller from GetX instance
                  controller: controller.artistNameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Artist Name",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade600)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                    errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                    focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent, width: 2)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter artist name' : null,
                ),
                SizedBox(height: 30),

                // --- Choose Image Button ---
                ElevatedButton.icon(
                  icon: Icon(Icons.image_search_rounded),
                  label: Text("Choose Cover Image"),
                  onPressed: () => controller.pickImage(), // Calls controller method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 20),

                // --- Image Preview ---
                Obx(() { // Reacts to imageDataBytes changes
                  final bytes = controller.imageDataBytes.value;
                  if (bytes != null) {
                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade700, width: 1)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory( // Use Image.memory
                            bytes,
                            height: 150, width: 150, fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                                height: 150, width: 150, color: Colors.grey.shade800,
                                child: Icon(Icons.broken_image, color: Colors.red, size: 50)),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Center( // Placeholder
                      child: Container(
                        height: 150, width: 150,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade700, width: 1)
                        ),
                        child: Center(child: Icon(Icons.photo_size_select_actual_outlined, color: Colors.grey.shade600, size: 50)),
                      ),
                    );
                  }
                }),
                SizedBox(height: 30),

                // --- Upload Button ---
                ElevatedButton.icon(
                  icon: Icon(Icons.cloud_upload_rounded),
                  label: Text("Upload Track"),
                  onPressed: () {
                    // Validate the form before calling upload
                    if (_formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus(); // Hide keyboard
                      // Call controller method WITHOUT arguments
                      controller.pickAndUpload();
                    } else {
                      Get.snackbar(
                          "Form Error",
                          "Please correct the errors and ensure an image is selected.",
                          snackPosition: SnackPosition.BOTTOM
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}