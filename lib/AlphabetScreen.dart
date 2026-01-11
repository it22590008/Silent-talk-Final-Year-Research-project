import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:fluttertoast/fluttertoast.dart';

import 'package:sign_research_2026/yolo_processor.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({Key? key}) : super(key: key);

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  late YoloProcessor _yoloProcessor;
  CameraController? _controller;

  late List<CameraDescription> _cameras;
  CameraDescription? _currentCamera;

  bool _isDetecting = false;
  bool _modelLoaded = false;

  List<Map<String, dynamic>> _detections = [];

  int _cameraFrameCount = 0;
  double _cameraFps = 0.0;
  DateTime _lastCameraTime = DateTime.now();

  //RANDOM LETTER
  final List<String> _alphabet =
  List.generate(26, (i) => String.fromCharCode(65 + i));
  final math.Random _random = math.Random();
  String _currentLetter = "A";
  DateTime _lastResultTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _yoloProcessor = YoloProcessor();
    _loadModel();
    _initializeCamera();
  }

  //LOAD MODEL
  Future<void> _loadModel() async {
    _modelLoaded = await _yoloProcessor.loadModel(
      labelsPath: 'assets/models/alphetbet_labels.txt',
      modelPath: 'assets/models/alphetbet_float32.tflite',
      modelVersion: "yolov8",
    );

    _generateRandomLetter();
    setState(() {});
  }

  //RANDOM LETTER
  void _generateRandomLetter() {
    setState(() {
      _currentLetter = _alphabet[_random.nextInt(_alphabet.length)];
    });
  }

  //CAMERA
  Future<void> _initializeCamera({CameraDescription? camera}) async {
    try {
      _cameras = await availableCameras();

      _currentCamera ??= _cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      if (camera != null) {
        _currentCamera = camera;
      }

      await _controller?.dispose();

      _controller = CameraController(
        _currentCamera!,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      setState(() {});

      _controller!.startImageStream((CameraImage image) {
        _cameraFrameCount++;
        final now = DateTime.now();
        final elapsed = now.difference(_lastCameraTime).inMilliseconds;

        if (elapsed >= 1000) {
          setState(() {
            _cameraFps = _cameraFrameCount * 1000 / elapsed;
          });
          _cameraFrameCount = 0;
          _lastCameraTime = now;
        }

        if (!_isDetecting && _modelLoaded) {
          _isDetecting = true;
          _runDetection(image);
        }
      });
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  //SWITCH CAMERA
  void _switchCamera() {
    if (_cameras.length < 2 || _currentCamera == null) return;

    final newCamera =
    _currentCamera!.lensDirection == CameraLensDirection.front
        ? _cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back)
        : _cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front);

    _initializeCamera(camera: newCamera);
  }

  //YOLO DETECTION
  Future<void> _runDetection(CameraImage image) async {
    try {
      final bytes = image.planes.map((p) => p.bytes).toList();

      final results = await _yoloProcessor.detectObjects(
        bytes,
        image.height,
        image.width,
      );

      if (results != null && results.isNotEmpty) {
        setState(() {
          _detections = results;
        });

        final best = results.reduce(
              (a, b) => a['box'][4] > b['box'][4] ? a : b,
        );

        final detectedLetter = best['tag'];
        final confidence = best['box'][4];

        if (confidence > 0.6 &&
            DateTime.now().difference(_lastResultTime).inSeconds > 2) {
          _lastResultTime = DateTime.now();

          if (detectedLetter == _currentLetter) {
            _showToast("✅ Correct : $detectedLetter", Colors.green);
          } else {
            _showToast(
                "❌ Wrong : Detected $detectedLetter", Colors.red);
          }
        }
      }
    } catch (e) {
      debugPrint("Detection error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  //TOAST
  void _showToast(String msg, Color color) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _yoloProcessor.closeModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alphabet Detection"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),

          CustomPaint(
            size: Size.infinite,
            painter: BoundingBoxPainter(
              detections: _detections,
              previewSize: _controller!.value.previewSize!,
              screenSize: MediaQuery.of(context).size,
              isFrontCamera: _currentCamera!.lensDirection ==
                  CameraLensDirection.front,
            ),
          ),

          Positioned(
            top: 20,
            right: 20,
            child: _infoBox("FPS: ${_cameraFps.toStringAsFixed(1)}"),
          ),

          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: "switchCamera",
              mini: true,
              backgroundColor: Colors.black.withOpacity(0.6),
              onPressed: _switchCamera,
              child:
              const Icon(Icons.cameraswitch, color: Colors.white),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _infoBox("Show Letter : $_currentLetter",
                  fontSize: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text, {double fontSize = 16}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

//BOUNDING BOX PAINTER
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size previewSize;
  final Size screenSize;
  final bool isFrontCamera;

  BoundingBoxPainter({
    required this.detections,
    required this.previewSize,
    required this.screenSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final labelBg = Paint()
      ..color = Colors.black.withOpacity(0.6);

    double scaleX = screenSize.width / previewSize.height;
    double scaleY = screenSize.height / previewSize.width;

    const double verticalOffset = 80;

    for (var det in detections) {
      final box = det['box'];
      if (box == null || box.length < 5) continue;

      double x = box[0] * scaleX;
      double y = box[1] * scaleY - verticalOffset;
      double w = (box[2] - box[0]) * scaleX;
      double h = (box[3] - box[1]) * scaleY;

      if (isFrontCamera) {
        x = screenSize.width - (x + w);
      }

      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.drawRect(rect, boxPaint);

      final labelRect = Rect.fromLTWH(x, math.max(0, y - 22), w, 22);
      canvas.drawRect(labelRect, labelBg);

      final textPainter = TextPainter(
        text: TextSpan(
          text: "${det['tag']} ${(box[4] * 100).toStringAsFixed(1)}%",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + 6, math.max(0, y - 20)),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}