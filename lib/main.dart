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
  bool isImageUpdated = true;

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

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        uploadImageToBRP_Mobile_Photo_Anomalies(context, _image);
        isImageUpdated = false;
      }
    });
  }
  List<String> imageUrls = [];

Future<void> captureMultiplePhotos() async {
  List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
  
  if (pickedFiles != null && pickedFiles.isNotEmpty) {
    for (var file in pickedFiles) {
      String fileName = path.basename(file.path);
      Reference ref = FirebaseStorage.instance
          .ref()
          .child("/BRP_Mobile_Photo_Anomalies/${todayDate}/id1/$fileName");
      
      UploadTask storageUploadTask = ref.putFile(File(file.path));
      TaskSnapshot taskSnapshot = await storageUploadTask.whenComplete(() {});
      
      String url = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    // Perform any additional actions with the uploaded image URLs
    print('Uploaded Image URLs: $imageUrls');
  }
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
      body: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * .3),
        alignment: Alignment.center,
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () {
                  _takePhoto();
                },
                child: Text("take a photo")),
            ElevatedButton(
              onPressed: isImageUpdated
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ImageDownloaderWidget()),
                      );
                      printFirebaseStorageFolders();
                    }
                  : null,
              child: Text("Download Images"),
            ),
            ElevatedButton(
              onPressed: () {
                getImages();
              },
              child: Text("Select Images from Gallery"),
            )
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     try {
      //       await _initializeControllerFuture;
      //       setState(() async {
      //         XFile _imagefile = await _controller.takePicture();
      //         _image = File(_imagefile.path);
      //         // _image = (await _controller.takePicture()).path as File;
      //         uploadImageToBRP_Mobile_Photo_Anomalies(context, _image);
      //       });
      //     } catch (e) {
      //       print(e);
      //     }
      //   },
      //   child: const Icon(Icons.camera_alt),
      // ),
    );
  }

  Future<void> getImages() async {
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 100, // To set quality of images
      maxHeight: 1000, // To set maxheight of images that you want in your app
      maxWidth: 1000, // To set maxheight of images that you want in your app
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      isImageUpdated = false;
      selectedImages =
          pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      for (var img in selectedImages) {
        uploadImageToBRP_Mobile_Photo_Anomalies(context, img);
      }
      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No images selected')));
    }
  }

  

  void uploadImageToBRP_Mobile_Photo_Anomalies(context, image) async {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(bucket: 'gs://fir-747ec.appspot.com');
    var todayDate =
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";
    print(todayDate);
    Reference ref = storage.ref().child(
        "/BRP_Mobile_Photo_Anomalies/${todayDate}/id1/${DateTime.now()}.jpg");
    UploadTask storageUploadTask = ref.putFile(image);
    TaskSnapshot taskSnapshot = await storageUploadTask.whenComplete(() {});
    print("success");
    String url = await taskSnapshot.ref.getDownloadURL();
    print('URL: $url');
    setState(() {
      _url = url;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image is successfully updated')));
    setState(() {
      isImageUpdated = true;
    });
  }

  void printFirebaseStorageFolders() async {
    final storageRef = FirebaseStorage.instance.ref().child("");
    final listResult = await storageRef.listAll();
    for (var prefix in listResult.prefixes) {
      print("----------------->${prefix.name} ");
      // The prefixes under storageRef.
      // You can call listAll() recursively on them.
    }
    for (var item in listResult.items) {
      // The items under storageRef.
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

  Future<void> _downloadImages() async {
    setState(() {
      _isLoading = true;
    });
    var todayDate =
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";
    try {
      firebase_storage.ListResult result = await firebase_storage
          .FirebaseStorage.instance
          .ref("/BRP_Mobile_Photo_Anomalies/${todayDate}/id1")
          .listAll();
      for (var ref in result.items) {
        String url = await ref.getDownloadURL();
        _downloadedUrls.add(url);
        print('URL: $url');
      }
    } catch (e) {
      print('Error occurred while downloading images: $e');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _downloadImages().then((value) {
      setState(() {
        _isLoading = false;
      });
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
          if (_isLoading)
            Center(
              heightFactor: 20,
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: (_downloadedUrls.length / 2).ceil(),
                itemBuilder: (context, index) {
                  int startIndex = index * 2;
                  int endIndex = startIndex + 1;
                  if (endIndex >= _downloadedUrls.length) {
                    endIndex = _downloadedUrls.length - 1;
                  }
                  List<String> imageUrls =
                      _downloadedUrls.sublist(startIndex, endIndex + 1);
                  return Row(
                    children: imageUrls.map((url) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            url,
                            width: 200,
                            height: 200,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
