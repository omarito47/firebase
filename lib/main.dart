import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker2/multi_image_picker2.dart';

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
  List<File> selectedImages = []; // List of selected image
  final picker = ImagePicker(); // Instance of Image picker

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
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ImageDownloaderWidget()),
                );
                    printFirebaseStorageFolders();

              },
              child: Text("Download Images")),
          ElevatedButton(
            onPressed: () {
              getImages();
            },
            child: Text("Select Images from Gallery"),
          )
        ],
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

  Future<void> getImages() async {
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 100, // To set quality of images
      maxHeight: 1000, // To set maxheight of images that you want in your app
      maxWidth: 1000, // To set maxheight of images that you want in your app
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      selectedImages =
          pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      for (var img in selectedImages) {
        uploadImageByparameter(context, img);
      }
      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No images selected')));
    }
  }

  void uploadImageByparameter(context, image) async {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(bucket: 'gs://fir-747ec.appspot.com');
    Reference ref =
        storage.ref().child("/firebaseImages/${DateTime.now()}.jpg");
    UploadTask storageUploadTask = ref.putFile(image);
    TaskSnapshot taskSnapshot = await storageUploadTask.whenComplete(() {});
    print("success");
    String url = await taskSnapshot.ref.getDownloadURL();
    print('URL: $url');
    setState(() {
      _url = url;
    });
  }

  void printFirebaseStorageFolders() async {
    final storage = FirebaseStorage.instance;
    final bucketUrl = 'gs://fir-747ec.appspot.com';

    firebase_storage.Reference storageRef = storage.ref().child('/data');
    List<firebase_storage.Reference> prefixes =
        (await storageRef.listAll()) as List<Reference>;

    for (firebase_storage.Reference prefix in prefixes) {
      print('Folder: ${prefix.name}');
    }
  }

  void uploadImage(context) async {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(bucket: 'gs://fir-747ec.appspot.com');
    Reference ref =
        storage.ref().child("/firebaseImages/${DateTime.now()}.jpg");
    UploadTask storageUploadTask = ref.putFile(_image);
    TaskSnapshot taskSnapshot = await storageUploadTask.whenComplete(() {});
    print("success");
    String url = await taskSnapshot.ref.getDownloadURL();
    print('URL: $url');
    setState(() {
      _url = url;
    });
  }
}

class ImageDownloaderWidget extends StatefulWidget {
  ImageDownloaderWidget();

  @override
  _ImageDownloaderWidgetState createState() => _ImageDownloaderWidgetState();
}

class _ImageDownloaderWidgetState extends State<ImageDownloaderWidget> {
  bool _isLoading = false;
  List<String> _downloadedUrls = [];

  void _downloadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      firebase_storage.ListResult result = await firebase_storage
          .FirebaseStorage.instance
          .ref("/firebaseImages/")
          .listAll();
      for (var ref in result.items) {
        String url = await ref.getDownloadURL();
        _downloadedUrls.add(url);
        print('URL: $url');
      }
    } catch (e) {
      print('Error occurred while downloading images: $e');
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
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _downloadImages();
            },
            child: Text('Download Images'),
          ),
          if (_isLoading)
            CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _downloadedUrls.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Image.network(_downloadedUrls[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
