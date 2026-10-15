import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '哨兵水印工具',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WatermarkPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WatermarkPage extends StatefulWidget {
  const WatermarkPage({super.key});

  @override
  State<WatermarkPage> createState() => _WatermarkPageState();
}

class _WatermarkPageState extends State<WatermarkPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String watermarkText = "风云T8哨兵";

  Future<void> pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _imageFile = img;
      });
    }
  }

  Future<void> saveImage() async {
    if (_imageFile == null) return;
    final Directory dir = await getTemporaryDirectory();
    final String savePath = "${dir.path}/water_${DateTime.now().millisecondsSinceEpoch}.jpg";
    File targetFile = File(savePath);
    await File(_imageFile!.path).copy(targetFile.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("图片保存成功")));
    }
  }

  Future<void> shareImage() async {
    if (_imageFile == null) return;
    await Share.shareXFiles([XFile(_imageFile!.path)], text: "哨兵截图");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("哨兵水印工具")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              value: watermarkText,
              decoration: const InputDecoration(labelText: "水印文字"),
              onChanged: (v) => setState(() => watermarkText = v),
            ),
            const SizedBox(height: 16),
            _imageFile != null
                ? Image.file(File(_imageFile!.path), height: 300)
                : const SizedBox(height: 300, child: Center(child: Text("请选择图片"))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: pickImage, child: const Text("选择图片")),
                ElevatedButton(onPressed: saveImage, child: const Text("保存")),
                ElevatedButton(onPressed: shareImage, child: const Text("分享")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
