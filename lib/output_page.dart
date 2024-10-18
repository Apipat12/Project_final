import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OutputPage extends StatelessWidget {
  final String name;
  final String description;
  final String type;
  final String use;
  final String SideEffect0;

  final FlutterTts flutterTts = FlutterTts();

  OutputPage({
    required this.name,
    required this.description,
    required this.type,
    required this.use,
    required this.SideEffect0,
  });

  Future<void> _speak() async {
    String text =
        "ชื่อ: $name, สรรพคุณของยา: $description, ผู้ที่เหมาะสมในการใช้: $use, ประเภทของยา: $type, ผลข้างเคียง: $SideEffect0";
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        title: const Text(''),
        centerTitle: true,
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF26A69A),Color(0xFFABFBE7)], // Gradient colors
              begin: Alignment.topCenter, // Starting point of the gradient
              end: Alignment.bottomCenter, // Ending point of the gradient
            ),
          ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (name.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16.0),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4.0,
                          spreadRadius: 1.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.isNotEmpty)
                        _buildOutputSection('สรรพคุณของยา:', description),
                      if (use.isNotEmpty)
                        _buildOutputSection('ผู้ที่เหมาะสมในการใช้:', use),
                      if (type.isNotEmpty)
                        _buildOutputSection('ประเภทของยา:', type),
                      if (SideEffect0.isNotEmpty)
                        _buildOutputSection('ผลข้างเคียง:', SideEffect0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speak,
        backgroundColor: Colors.black38,
        child: Icon(Icons.volume_up, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // วางปุ่มตรงกลางล่างจอ
    );
  }

  Widget _buildOutputSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
