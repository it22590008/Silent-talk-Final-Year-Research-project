import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sign_research_2026/yolo_processor.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Chat extends StatefulWidget {
  final String peerId;
  final String peerName;

  const Chat({Key? key, required this.peerId, required this.peerName})
    : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  String? currentUserId;
  String? lastSpokenMessageId;
  final TextEditingController messageController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

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

  String? _lastDetected;
  String received_msg = "";

  @override
  void initState() {
    super.initState();
    _yoloProcessor = YoloProcessor();
    _loadModel();
    _initializeCamera();
    loadUser();
  }

  //LOAD MODEL
  Future<void> _loadModel() async {
    _modelLoaded = await _yoloProcessor.loadModel(
      labelsPath: 'assets/models/words_labels.txt',
      modelPath: 'assets/models/words_float32.tflite',
      modelVersion: "yolov8",
    );
    setState(() {});
  }

  //CAMERA INIT
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

      _controller!.startImageStream((image) {
        _cameraFrameCount++;
        final now = DateTime.now();
        final elapsed = now.difference(_lastCameraTime).inMilliseconds;

        if (elapsed >= 1000) {
          _cameraFps = _cameraFrameCount * 1000 / elapsed;
          _cameraFrameCount = 0;
          _lastCameraTime = now;
          setState(() {});
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
    if (_cameras.length < 2) return;

    final newCamera = _currentCamera!.lensDirection == CameraLensDirection.front
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
          )
        : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
          );

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

      if (results != null && results.isNotEmpty) {
        final tag = results.first['tag'];

        if (tag != _lastDetected) {
          sendMessage(tag);
          setState(() {
            _lastDetected = tag;
            _detections = results;
          });
        }
      }
    } catch (e) {
      debugPrint("Detection error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _yoloProcessor.closeModel();
    super.dispose();
  }

  /// Load current user ID from SharedPreferences
  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('userid');

    if (id != null) {
      setState(() {
        currentUserId = id;
      });
    }
  }

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Send message
  void sendMessage(String text) async {
    if (text.isEmpty || currentUserId == null) {
      print("usernot");
      return;
    }else{
      String chatId = getChatId(currentUserId!, widget.peerId);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId!,
        'receiverId': widget.peerId,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      messageController.clear();
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final word = received_msg.toLowerCase();
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.peerName)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String chatId = getChatId(currentUserId!, widget.peerId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                CameraPreview(_controller!),

                CustomPaint(
                  size: Size.infinite,
                  painter: BoundingBoxPainter(
                    detections: _detections,
                    previewSize: _controller!.value.previewSize!,
                    screenSize: MediaQuery.of(context).size,
                    isFrontCamera:
                        _currentCamera!.lensDirection ==
                        CameraLensDirection.front,
                  ),
                ),

                Positioned(top: 16, right: 16, child: _fpsWidget()),
                Positioned(top: 16, left: 16, child: _cameraSwitchButton()),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text("No messages"));

                var lastMessage = docs.last;
                String senderId = lastMessage['senderId'];
                String messageId = lastMessage.id;

                if (senderId != currentUserId &&
                    messageId != lastSpokenMessageId) {
                  lastSpokenMessageId = messageId;
                  speak(lastMessage['text']);
                  setState(() {
                    received_msg = lastMessage['text'];
                  });
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/signs/$word.png', height: 240),
                    const SizedBox(height: 10),

                    Text(
                      word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fpsWidget() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "FPS: ${_cameraFps.toStringAsFixed(1)}",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _cameraSwitchButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.black.withOpacity(0.6),
      onPressed: _switchCamera,
      child: const Icon(Icons.cameraswitch, color: Colors.white),
    );
  }
}

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

    final labelBg = Paint()..color = Colors.black.withOpacity(0.6);

    double scaleX = screenSize.width / previewSize.height;
    double scaleY = screenSize.height / previewSize.width;

    for (var det in detections) {
      final box = det['box'];
      if (box == null || box.length < 5) continue;

      double x = box[0] * scaleX;
      double y = box[1] * scaleY;
      double w = (box[2] - box[0]) * scaleX;
      double h = (box[3] - box[1]) * scaleY;

      if (isFrontCamera) x = screenSize.width - (x + w);

      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.drawRect(rect, boxPaint);

      final labelRect = Rect.fromLTWH(x, y - 22, w, 22);
      canvas.drawRect(labelRect, labelBg);

      final textPainter = TextPainter(
        text: TextSpan(
          text: "${det['tag']} ${(box[4] * 100).toStringAsFixed(1)}%",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 6, y - 20));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
