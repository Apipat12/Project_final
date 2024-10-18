import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'output_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _responseMessage = ''; // ประกาศตัวแปร _responseMessage

  void _pickImageFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemp = File(image.path);
      setState(() {
        _imageFile = imageTemp;
      });
      uploadImage(_imageFile!);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  void _pickImageFromCamera() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final imageTemp = File(image.path);
      setState(() {
        _imageFile = imageTemp;
      });
      uploadImage(_imageFile!);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<void> uploadImage(File imageFile) async {
    var apiUrl = Uri.parse('http://172.16.21.46:8000/predict/');

    var request = http.MultipartRequest('POST', apiUrl);

    var fileStream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();
    var multipartFile = http.MultipartFile('file', fileStream, length,
        filename: imageFile.path
            .split('/')
            .last);

    request.files.add(multipartFile);

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.transform(utf8.decoder).join();
      var jsonResponse = jsonDecode(responseData);
      if (jsonResponse is Map<String, dynamic>) {
        String name = jsonResponse['name'] ?? '';
        String description = jsonResponse['description'] ?? '';
        String type = jsonResponse['type'] ?? '';
        String use = jsonResponse['use'] ?? '';
        String SideEffect0 = jsonResponse['SideEffect0'] ?? '';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OutputPage(
                  name: name,
                  description: description,
                  type: type,
                  use: use,
                  SideEffect0: SideEffect0,
                ),
          ),
        );
      } else {
        setState(() {
          _responseMessage = 'รูปแบบการตอบกลับไม่ถูกต้อง';
        });
      }
    } else {
      setState(() {
        _responseMessage = 'อัปโหลดรูปภาพล้มเหลว: ${response.reasonPhrase}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100, // เพิ่มความสูงของ AppBar
        backgroundColor: Color(0xFF26A69A), // สีพื้นหลัง
        elevation: 0, // ไม่มีเงา
        centerTitle: true, // ตำแหน่งกลาง
        title: const Text(
          'Medicine Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold, // ตัวหนา
            fontSize: 26, // ปรับขนาดตัวอักษร
            color: Colors.white, // สีของตัวอักษร
            letterSpacing: 1.2, // ระยะห่างระหว่างตัวอักษรเล็กน้อยเพื่อความสวยงาม
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF26A69A),Color(0xFFABFBE7)], // Gradient colors
            begin: Alignment.topCenter, // Starting point of the gradient
            end: Alignment.bottomCenter, // Ending point of the gradient
          ),
        ), // Background color for the entire body
        child: SingleChildScrollView(
          // Allows scrolling when content exceeds screen size
          child: Column(
            children: [
              Container(
                height: 400,
                //color: Colors.white12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                      width: 320, // Set the desired width
                      height: 120, // Set the desired height
                      child: MaterialButton(
                        color: Colors.white54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30.0), // Rectangular with slight rounding
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(11.0),
                          child: Row(
                            children: [
                              // Icon with background color
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFAb91),
                                  // Yellowish-orange color for icon background
                                  shape: BoxShape.circle, // Circle shape to wrap the icon
                                ),
                                padding: const EdgeInsets.all(10.0),
                                // Padding around the icon
                                child: Icon(Icons.camera_alt,
                                    color: Colors.black, size: 50),
                              ),
                              const SizedBox(width: 20, height: 30),
                              // Space between icon and text
                              const Text(
                                "Camera",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25 ,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPressed: _pickImageFromCamera,
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: 320, // Set the desired width
                      height: 120, // Set the desired height
                      child: MaterialButton(
                        color: Colors.white54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30.0), // Rectangular with slight rounding
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(11.0),
                          child: Row(
                            children: [
                              // Icon with background color
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFCE93B8),
                                  // Light blue color for icon background
                                  shape: BoxShape.circle, // Circle shape to wrap the icon
                                ),
                                padding: const EdgeInsets.all(10.0),
                                // Padding around the icon
                                child: Icon(Icons.photo,
                                    color: Colors.black, size: 50),
                              ),
                              const SizedBox(width: 20, height: 30),
                              // Space between icon and text
                              const Text(
                                "Gallery",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPressed: _pickImageFromGallery ,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 480,
                // You can remove the fixed height if scrolling is applied
                //color: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
