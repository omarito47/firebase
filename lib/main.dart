import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late File _image;
  late String _url;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            setState(() async {
              XFile _imagefile = await _controller.takePicture();
              _image = File(_imagefile.path);
              // _image = (await _controller.takePicture()).path as File;
              uploadImage(context);
            });
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  void uploadImage(context) async {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(bucket: 'gs://fir-747ec.appspot.com');
    Reference ref = storage.ref().child(_image.path);
    UploadTask storageUploadTask = ref.putFile(_image);
    TaskSnapshot taskSnapshot = await storageUploadTask.whenComplete(() {});
    print("success");
    String url = await taskSnapshot.ref.getDownloadURL();
    print('URL: $url');
    setState(() {
      _url = url;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ImageDownloaderWidget(imageUrl: _url)),
    );
  }
}

class ImageDownloaderWidget extends StatefulWidget {
  final String imageUrl;

  ImageDownloaderWidget({required this.imageUrl});

  @override
  _ImageDownloaderWidgetState createState() => _ImageDownloaderWidgetState();
}

class _ImageDownloaderWidgetState extends State<ImageDownloaderWidget> {
  bool _isLoading = false;
  String _downloadedImagePath = '';

  void _downloadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        String savePath =
            '/path/to/save/image.jpg'; // Provide the desired save path
        File file = File(savePath);
        file.writeAsBytesSync(response.bodyBytes);
        setState(() {
          _downloadedImagePath = savePath;
        });
        print('Image downloaded successfully.');
      } else {
        print('Failed to download image. Error code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while downloading image: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Downloader'),
      ),
      body: Image.network(widget.imageUrl),
    );
  }
}
