import 'dart:io';
import 'dart:ui' as ui;
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
      title: '图片水印工具',
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
  XFile? _originImage;
  File? _wateredImage;
  final TextEditingController _watermarkCtrl = TextEditingController(text: "自定义水印");

  Future<void> pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _originImage = img;
        _wateredImage = null;
      });
    }
  }

  Future<void> addWatermark() async {
    if (_originImage == null || _watermarkCtrl.text.trim().isEmpty) return;

    final ui.Image origin = await decodeImageFromList(await _originImage!.readAsBytes());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 绘制原图
    canvas.drawImage(origin, Offset.zero, Paint());

    // 绘制水印文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: _watermarkCtrl.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 右下角水印位置，距离边距50
    final dx = origin.width - textPainter.width - 50;
    final dy = origin.height - textPainter.height - 50;
    textPainter.paint(canvas, Offset(dx, dy));

    final ui.Image outImg = await recorder.endRecording().toImage(origin.width, origin.height);
    final ByteData? byteData = await outImg.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final Directory tempDir = await getTemporaryDirectory();
    final File outFile = File("${tempDir.path}/water_${DateTime.now().millisecondsSinceEpoch}.png");
    await outFile.writeAsBytes(pngBytes);

    setState(() {
      _wateredImage = outFile;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("水印添加成功！")));
    }
  }

  Future<void> shareImage() async {
    if (_wateredImage == null) return;
    await Share.shareXFiles([XFile(_wateredImage!.path)], text: "水印图片");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("图片水印工具")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _watermarkCtrl,
              decoration: const InputDecoration(labelText: "水印文字", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: pickImage, child: const Text("选择图片")),
            const SizedBox(height: 16),
            if (_originImage != null)
              Image.file(File(_originImage!.path), height: 280, fit: BoxFit.contain),
            const SizedBox(height:12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: addWatermark, child: const Text("添加水印")),
                const SizedBox(width:10),
                ElevatedButton(onPressed: shareImage, child: const Text("分享图片")),
              ],
            ),
            const SizedBox(height:16),
            if (_wateredImage != null)
              Column(
                children: [
                  const Text("✅ 添加水印后预览"),
                  Image.file(_wateredImage!, height:280, fit: BoxFit.contain),
                ],
              )
          ],
        ),
      ),
    );
  }
}
