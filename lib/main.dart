import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shimmer/shimmer.dart';

import 'CameraApp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Directory? galleryDirectory = await getExternalStorageDirectory();
  print("==== ${galleryDirectory?.path}");

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  bool isImageUpdated = true;

  late CameraController _controller;
  late File _image;
  late String _url;
  List<File> selectedImages = []; // List of selected image
  final picker = ImagePicker(); // Instance of Image picker

  @override
  void initState() {
    super.initState();
  }

  Future<void> _takePhoto() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraApp(),
      ),
    );
  }

  List<String> imageUrls = [];

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
    );
  }

  Future<void> getImages() async {
    setState(() {
      isImageUpdated = false;
    });
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 100, // To set quality of images
      maxHeight: 1000, // To set maxheight of images that you want in your app
      maxWidth: 1000, // To set maxheight of images that you want in your app
    );
    var length = 0;

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      isImageUpdated = false;
      selectedImages =
          pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();

      for (var img in selectedImages) {
        uploadImageToBRP_Mobile_Photo_Anomalies(context, img);
        length += 1;
      }

      if (length == selectedImages.length) {
        setState(() {
          isImageUpdated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is successfully updated')));
      }
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
          .ref("/BRP_Mobile_Photo_Anomalies/$todayDate/id1")
          .listAll();
      for (var ref in result.items) {
        String url = await ref.getDownloadURL();
        _downloadedUrls.add(url);
        print('URL: $url');
      }
    } catch (e) {
      print('Error occurred while downloading images: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _downloadImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Downloader'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _downloadedUrls.length,
              itemBuilder: (context, index) {
                String url = _downloadedUrls[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    url,
                    width: 200,
                    height: 200,
                  ),
                );
              },
            ),
    );
  }
}
