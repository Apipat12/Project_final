import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_picker/main2.dart';
import 'main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home3(), // Your Home widget as the starting screen
    );
  }
}

class Home3 extends StatefulWidget {
  const Home3({Key? key}) : super(key: key);

  @override
  State<Home3> createState() => _HomeState();
}

class _HomeState extends State<Home3> {

  void navigateToNextPageTH(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Home()), // Replace 'NextPage' with your desired page widget
    );
  }
  void navigateToNextPageENG(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Home2()), // Replace 'NextPage' with your desired page widget
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100, // เพิ่มความสูงของ AppBar
        backgroundColor: const Color(0xFFABFBE7), // สีพื้นหลัง
        elevation: 0, // ไม่มีเงา
        centerTitle: true, // ตำแหน่งกลาง
        title: const Text(
          ' Medicine Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold, // ตัวหนา
            fontSize: 26, // ปรับขนาดตัวอักษร
            color: Colors.black54, // สีของตัวอักษร
            letterSpacing:
            1.2, // ระยะห่างระหว่างตัวอักษรเล็กน้อยเพื่อความสวยงาม
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFABFBE7), Color(0xFF26A69A)], // Gradient colors
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Text(
                        'เลือกภาษา',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 210, // Set the desired width
                      height: 82, // Set the desired height
                      child: MaterialButton(
                        color: Colors.white54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30.0), // Rectangular with slight rounding
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            children:  [
                              // Icon with background color
                              Container(
                                //decoration: const BoxDecoration(
                                //color: Color(0xFFCE93B8),
                                // Light blue color for icon background
                                // shape: BoxShape
                                //.circle, // Circle shape to wrap the icon
                                //),
                                padding: const EdgeInsets.all(1.0),
                                // Padding around the icon
                                child: const Icon(Icons.flag_rounded,
                                    color: Colors.black87, size: 30),
                              ),
                              const SizedBox(width: 10, height: 30),
                              // Space between icon and text
                              const Text(
                                "ภาษาไทย",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Home2()), // Replace 'NextPage' with your desired page widget
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 215, // Set the desired width
                      height: 85, // Set the desired height
                      child: MaterialButton(
                        color: Colors.white54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30.0), // Rectangular with slight rounding
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(13.0),
                          child: Row(
                            children:  [
                              Container(
                                  //decoration: const BoxDecoration(
                                    //color: Color(0xFFCE93B8),
                                    // Light blue color for icon background
                                   // shape: BoxShape
                                        //.circle, // Circle shape to wrap the icon
                                  //),
                                  padding: const EdgeInsets.all(1.0),
                                  // Padding around the icon
                                  child: const Icon(Icons.flag_rounded,
                                      color: Colors.black87, size: 30),
                                ),
                               const SizedBox(width: 10, height: 30),
                              // Space between icon and text
                               const Text(
                                "ภาษาอังกฤษ",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ) ,
                        ),
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Home()), // Replace 'NextPage' with your desired page widget
                          );
                        },
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
