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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home2(), // Your Home widget as the starting screen
    );
  }
}

class Home2 extends StatefulWidget {
  const Home2({Key? key}) : super(key: key);

  @override
  State<Home2> createState() => _HomeState();
}

class _HomeState extends State<Home2> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _responseMessage = ''; // ประกาศตัวแปร _responseMessage

  //ฟังก์ชันเรียกเพื่อเปิดแกลเลอรี
  void _pickImageFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;//ถ้า image เป็น null จะหยุดการทำงาน
      final imageTemp = File(image.path);//เก็บข้อมูลของภาพในรูปแบบของไฟล์เป็น path ของรูปภาพ
      setState(() {
        _imageFile = imageTemp;//อัปเดตข้อมูลกำหนด _imageFile เป็นภาพที่เลือก
      });
      //เรียกฟังก์ชัน uploadImage เพื่อทำการอัปโหลดภาพไปยัง API
      //บังคับไม่ให้ _imageFile เป็น null ตรวจสอบแล้วภาพถูกเลือก
      uploadImage(_imageFile!);

    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  //ฟังก์ชันเรียกเพื่อเปิดกล้อง
  void _pickImageFromCamera() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;//ถ้า image เป็น null จะหยุดการทำงาน
      final imageTemp = File(image.path);//เก็บข้อมูลของภาพในรูปแบบของไฟล์เป็น path ของรูปภาพ
      setState(() {
        _imageFile = imageTemp;//อัปเดตข้อมูลกำหนด _imageFile เป็นภาพที่เลือก
      });
      //เรียกฟังก์ชัน uploadImage เพื่อทำการอัปโหลดภาพไปยัง API
      //บังคับไม่ให้ _imageFile เป็น null ตรวจสอบแล้วภาพถูกเลือก
      uploadImage(_imageFile!);

    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  //ฟังก์ชัน
  Future<void> uploadImage(File imageFile) async {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิด dialog หมุน
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),// แสดงตัวหมุนรอการอัปโหลด
        );
      },
    );
    // URL ที่ใช้ในการอัปโหลดภาพไปยัง API
    var apiUrl = Uri.parse('http://172.16.20.253:8000/predictTH/');
    // ส่งไฟล์ภาพแบบ multipart ไปยัง API
    var request = http.MultipartRequest('POST', apiUrl);

    var fileStream = http.ByteStream(imageFile.openRead());
    // เก็บขนาดของไฟล์ภาพที่กำลังจะถูกส่ง
    var length = await imageFile.length();
    // ไฟล์ MultipartFile จะถูกเพิ่มเข้าไปใน request สำหรับการอัปโหลด
    var multipartFile = http.MultipartFile('file', fileStream, length,
        filename: imageFile.path.split('/').last);
    request.files.add(multipartFile);// เพิ่มไฟล์ภาพเข้าไป

    // ส่ง API โดยใช้ request.send() และรอตอบกลับ
    var response = await request.send();

    if (response.statusCode == 200) { // ถ้า status เป็น 200 แสดงว่าอัปโหลดสำเร็จ
      print('Upload successful');
      var responseData = await response.stream.transform(utf8.decoder).join(); //ข้อมูลจาก API แปลงเป็นข้อความ
      var jsonResponse = jsonDecode(responseData);
      if (jsonResponse is Map<String, dynamic>) {
        // ดึงข้อมูลจากการตอบกลับเป็นค่าต่างๆ ถ้าไม่มีข้อมูลให้เป็นค่าว่าง
        String name = jsonResponse['name'] ?? '';
        String description = jsonResponse['description'] ?? '';
        String type = jsonResponse['type'] ?? '';
        String use = jsonResponse['use'] ?? '';
        String therapeutic_class = jsonResponse['therapeutic_class'] ?? '';
        String use0 = jsonResponse['use0'] ?? '';
        String side_effect0 = jsonResponse['side_effect0'] ?? '';
        String error = jsonResponse['error'] ?? '';
        // ปิดหมุนหลังจากการตอบกลับเสร็จสิ้น
        Navigator.of(context).pop();

        // ทางไปหน้า OutputPage
        Navigator.push(
          context,
          MaterialPageRoute(
            //เมื่อได้รับข้อมูลจาก API จะนำทางไปยังหน้า OutputPage พร้อมกับส่งข้อมูลที่ได้รับไปแสดงในหน้านั้น
            builder: (context) => OutputPage(
                name: name,
                description: description,
                type: type,
                use: use,
                therapeutic_class: therapeutic_class,
                use0: use0,
                side_effect0: side_effect0,
                error:error
            ),
          ),
        );
      } else {
        setState(() {
          _responseMessage = 'รูปแบบการตอบกลับไม่ถูกต้อง';
          print(_responseMessage);
        });
        // ปิดหมุนหลังจากการตอบกลับเสร็จสิ้น
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _responseMessage = 'อัปโหลดรูปภาพล้มเหลว: ${response.reasonPhrase}';
        print(_responseMessage);
      });
      // ปิดหมุนหลังจากการตอบกลับเสร็จสิ้น
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100, // เพิ่มความสูงของ AppBar
        backgroundColor: const Color(0xFF26A69A), // สีพื้นหลัง
        elevation: 0, // ไม่มีเงา
        centerTitle: true, // ตำแหน่งกลาง
        title: const Text(
          'Medicine Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold, // ตัวหนา
            fontSize: 26, // ปรับขนาดตัวอักษร
            color: Colors.white, // สีของตัวอักษร
            letterSpacing:
            1.2, // ระยะห่างระหว่างตัวอักษรเล็กน้อยเพื่อความสวยงาม
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFFABFBE7)], // Gradient colors
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFAb91),
                                  // Yellowish-orange color for icon background
                                  shape: BoxShape
                                      .circle, // Circle shape to wrap the icon
                                ),
                                padding: const EdgeInsets.all(10.0),
                                // Padding around the icon
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.black87, size: 50),
                              ),
                              const SizedBox(width: 20, height: 30),
                              // Space between icon and text
                              const Text(
                                "เปิดกล้อง",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCE93B8),
                                  // Light blue color for icon background
                                  shape: BoxShape
                                      .circle, // Circle shape to wrap the icon
                                ),
                                padding: const EdgeInsets.all(10.0),
                                // Padding around the icon
                                child: const Icon(Icons.photo,
                                    color: Colors.black87, size: 50),
                              ),
                              const SizedBox(width: 20, height: 30),
                              // Space between icon and text
                              const Text(
                                "เปิดรูปภาพ",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPressed: _pickImageFromGallery,
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 50),//80
              Container(height: 240)
            ],
          ),
        ),
      ),
    );
  }
}
