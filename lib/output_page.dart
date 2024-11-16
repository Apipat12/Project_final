import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OutputPage extends StatelessWidget {
  final String name;
  final String description;
  final String type;
  final String use;
  final String therapeutic_class;
  final String use0;
  final String side_effect0;
  final String error;

  final FlutterTts flutterTts = FlutterTts();

  OutputPage({
    required this.name,
    required this.description,
    required this.type,
    required this.use,
    required this.therapeutic_class,
    required this.use0,
    required this.side_effect0,
    required this.error,
  });

  Future<void> _speak() async {
    StringBuffer text = StringBuffer();

    // ตรวจสอบและเพิ่มข้อมูลที่มีค่า
    if (name.isNotEmpty) {
      text.write("ชื่อ: $name, ");
    }
    if (description.isNotEmpty) {
      text.write("สรรพคุณของยา: $description, ");
    }
    if (use.isNotEmpty) {
      text.write("ผู้ที่เหมาะสมในการใช้: $use, ");
    }
    if (type.isNotEmpty) {
      text.write("ประเภทของยา: $type, ");
    }
    if (therapeutic_class.isNotEmpty) {
      text.write("Medicine Class: $therapeutic_class, ");
    }
    if (use0.isNotEmpty) {
      text.write("Description: $use0, ");
    }
    if (side_effect0.isNotEmpty) {
      text.write("SideEffect: $side_effect0");
    }

    // แปลงเป็น String และลบเครื่องหมาย comma
    String finalText = text.toString().trim();
    if (finalText.endsWith(",")) {
      finalText = finalText.substring(0, finalText.length - 1);
    }

    // พูดข้อความ
    if (finalText.isNotEmpty) {
      await flutterTts.speak(finalText);
    } else {
      print('No information available to speak.');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAllDataEmpty =
        name.isEmpty &&
        description.isEmpty &&
        use.isEmpty &&
        type.isEmpty &&
        therapeutic_class.isEmpty &&
        use0.isEmpty &&
        side_effect0.isEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        title: const Text(''),
        centerTitle: true,
      ),
      body: Container(
          decoration: const BoxDecoration(
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
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: const [
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: isAllDataEmpty
                      ? Center(
                    child: Text(
                      error.isNotEmpty ? error : error,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  )
                  :Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (description.isNotEmpty)
                          _buildOutputSection('สรรพคุณของยา:', description),
                        if (use.isNotEmpty)
                          _buildOutputSection('ผู้ที่เหมาะสมในการใช้:', use),
                        if (type.isNotEmpty)
                          _buildOutputSection('ประเภทของยา:', type),
                        if (therapeutic_class.isNotEmpty)
                          _buildOutputSection('Medicine Class:',therapeutic_class),
                        if (use0.isNotEmpty)
                          _buildOutputSection('Description:', use0),
                        if (side_effect0.isNotEmpty)
                          _buildOutputSection('SideEffect:', side_effect0),
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
        child: const Icon(Icons.volume_up, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // วางปุ่มตรงกลางล่างจอ
    );
  }

  Widget _buildOutputSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
