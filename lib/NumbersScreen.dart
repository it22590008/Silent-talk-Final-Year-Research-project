import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:sign_research_2026/yolo_processor.dart';

class NumbersScreen extends StatefulWidget {
  const NumbersScreen({Key? key}) : super(key: key);

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  late YoloProcessor _yoloProcessor;
  CameraController? _controller;

  late List<CameraDescription> _cameras;
  CameraDescription? _currentCamera;

  bool _isDetecting = false;
  bool _modelLoaded = false;
  bool _answered = false;

  List<Map<String, dynamic>> _detections = [];

  int _cameraFrameCount = 0;
  double _cameraFps = 0.0;
  DateTime _lastCameraTime = DateTime.now();

  // Q Numbers
  int _numA = 0;
  int _numB = 0;
  int _correctAnswer = 0;

  @override
  void initState() {
    super.initState();
    _yoloProcessor = YoloProcessor();
    _generateQuestion();
    _loadModel();
    _initializeCamera();
  }

  //random numbers
  void _generateQuestion() {
    final rnd = math.Random();
    _numA = rnd.nextInt(5);
    _numB = rnd.nextInt(6);
    _correctAnswer = _numA + _numB;
  }

  //LOAD YOLO MODEL
  Future<void> _loadModel() async {
    _modelLoaded = await _yoloProcessor.loadModel(
      labelsPath: 'assets/models/numbers_labels.txt',
      modelPath: 'assets/models/numbers_float32.tflite',
      modelVersion: "yolov8",
    );
    setState(() {});
  }

  //CAMERA
  Future<void> _initializeCamera({CameraDescription? camera}) async {
    try {
      _cameras = await availableCameras();

      _currentCamera ??= _cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      if (camera != null) _currentCamera = camera;

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

        if (!_isDetecting && _modelLoaded && !_answered) {
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

  Future<void> _runDetection(CameraImage image) async {
    try {
      final bytes = image.planes.map((p) => p.bytes).toList();

      final results = await _yoloProcessor.detectObjects(
        bytes,
        image.height,
        image.width,
      );

      if (results != null && results.isNotEmpty && !_answered) {
        final det = results.first;
        final detectedLabel = det['tag'];
        final detectedNumber = int.tryParse(detectedLabel);

        if (detectedNumber != null) {
          _answered = true;

          if (detectedNumber == _correctAnswer) {
            _showToast("✅ Correct Answer!");
          } else {
            _showToast("❌ Wrong Answer");
          }
        }

        setState(() {
          _detections = results;
        });
      }
    } catch (e) {
      debugPrint("Detection error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
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
        title: const Text("Number Quiz"),
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
              isFrontCamera:
              _currentCamera!.lensDirection == CameraLensDirection.front,
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$_numA + $_numB = ?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: "switchCamera",
              mini: true,
              backgroundColor: Colors.black.withOpacity(0.6),
              onPressed: _switchCamera,
              child: const Icon(Icons.cameraswitch, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

//BOUNDING BOX
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
