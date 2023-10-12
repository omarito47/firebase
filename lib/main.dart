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
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import "package:intl/intl.dart";
import 'package:camerawesome/camerawesome_plugin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Directory? galleryDirectory = await getExternalStorageDirectory();
  print("==== ${galleryDirectory?.path}");

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraApp(),
      ),
    );
    // final picker = ImagePicker();
    // final pickedFile = await picker.pickImage(
    //   source: ImageSource.camera,
    //   imageQuality: 50,
    // );

    // if (pickedFile != null) {

    //   // setState(() {
    //   //   _image = File(pickedFile.path);
    //   //   //uploadImageToBRP_Mobile_Photo_Anomalies(context, _image);

    //   //   //isImageUpdated = false;
    //   // });
    //   // await ImageGallerySaver.saveFile(pickedFile.path)
    //   //     .then((value) => getImages());
    // }
  }

  List<String> imageUrls = [];

// Future<void> captureMultiplePhotos() async {
//   List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();

//   if (pickedFiles != null && pickedFiles.isNotEmpty) {
//     for (var file in pickedFiles) {
//       String fileName = path.basename(file.path);
//       Reference ref = FirebaseStorage.instance
//           .ref()
//           .child("/BRP_Mobile_Photo_Anomalies/${todayDate}/id1/$fileName");

//       UploadTask storageUploadTask = ref.putFile(File(file.path));
//       TaskSnapshot taskSnapshot = await storageUploadTask.whenComplete(() {});

//       String url = await taskSnapshot.ref.getDownloadURL();
//       imageUrls.add(url);
//     }

//     // Perform any additional actions with the uploaded image URLs
//     print('Uploaded Image URLs: $imageUrls');
//   }
// }

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

class CameraApp extends StatefulWidget {
  final bool isMultiple;
  final bool isSimpleUI;
  final int? compressionQuality;
  final int? compressedSize;

  const CameraApp(
      {Key? key,
      this.isMultiple = false,
      this.isSimpleUI = true,
      this.compressedSize,
      this.compressionQuality = 100})
      : super(key: key);

  @override
  CameraAppState createState() => CameraAppState();
}

class CameraAppState extends State<CameraApp> {
  CameraController? controller;
  late List<CameraDescription> cameras;
  static List<Album> imageAlbums = [];
  static Set<Medium> imageMedium = {};
  Uint8List? bytes;
  List<File> results = [];
  List<int> indexList = [];
  bool flashOn = false;
  int camIndex = 0;
  bool showPerformance = false;
  late double width;
  int pageIndex = 1;
  int pageCount = 10;
  int pageIndex2 = 1;
  int pageCount2 = 50;

  int count = 0;
  int count2 = 0;
  ScrollController bottomController = ScrollController();
  ScrollController topController = ScrollController();
  int scroll = 0;

  ///The controller of sliding up panel
  SlidingUpPanelController panelController = SlidingUpPanelController();

  bool isImageSelected = false;
  bool isProcessDone = false;

  static List<Map<String, dynamic>> selectedImages = [];

  void fillUpImagesList(List imageListPath) {
    for (var i = 0; i < imageListPath.length; i++) {
      selectedImages.add({
        'id': i,
        'imagePath': imageFromgallery[i],
        'selected': false,
      });
      i == imageListPath.length - 1
          ? setState(() {
              isProcessDone = true;
            })
          : {};
    }
  }

  moduleProcessing() async {
    await loadImages();
    await cameraLoad();

    fillUpImagesList(imageFromgallery);
  }

  @override
  void initState() {
    super.initState();

    moduleProcessing();

    // loadImages();
    // cameraLoad();
  }

  cameraLoad() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.max,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : null);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _promptPermissionSetting().then((_) {
        if (_) {
          loadImages();
        }
        setState(() {});
      });

      setState(() {});
    });
    bottomController.addListener(() {
      if (bottomController.position.atEdge) {
        bool isTop = bottomController.position.pixels == 0;
        if (!isTop) {
          if (imageMedium.length > (pageCount2 * pageIndex2)) {
            setState(() {
              pageIndex2++;
            });
            if (pageCount2 * (pageIndex2) > imageMedium.length) {
              //fix here
              count2 = imageMedium.length;
            } else {
              count2 = pageCount2 * pageIndex2;
            }
          }
        }
      }
    });
    topController.addListener(() {
      if (topController.position.atEdge) {
        bool isTop = topController.position.pixels == 0;
        if (!isTop) {
          if (imageMedium.length > (pageCount * pageIndex)) {
            setState(() {
              pageIndex++;
            });
            if (pageCount * (pageIndex) > imageMedium.length) {
              //fix here
              count = imageMedium.length;
            } else {
              count = pageCount * pageIndex;
            }
          }
        }
      }
    });
  }

  Future<bool> _promptPermissionSetting() async {
    if (kIsWeb) {
      return true;
    } else if (Platform.isIOS) {
      PermissionStatus status = await Permission.storage.request();
      PermissionStatus status2 = await Permission.photos.request();
      PermissionStatus status3 = await Permission.mediaLibrary.request();
      return status.isGranted && status2.isGranted && status3.isGranted;
    } else if (Platform.isAndroid) {
      PermissionStatus status = await Permission.storage.request();
      return status.isGranted;
    }
    return false;
  }

  static var imageFromgallery = [];
  loadImages() async {
    imageAlbums = await PhotoGallery.listAlbums(
      mediumType: MediumType.image,
    );
    imageMedium = {};
    for (var element in imageAlbums) {
      var data = await element.listMedia();

      imageMedium.addAll(data.items);
    }
    for (var element in imageMedium) {
      File file = await element.getFile();

      imageFromgallery.add(file);
    }

    setState(() {});
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  final List<String> imageUrls = [
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    'https://firebasestorage.googleapis.com/v0/b/fir-747ec.appspot.com/o/BRP_Mobile_Photo_Anomalies%2F10-10-2023%2Fid1%2F2023-10-10%2013%3A24%3A21.260669.jpg?alt=media&token=1f815e3d-d17e-4e18-b40c-eb54990bb982&_gl=1*1nu4f68*_ga*MTIwMzM5NDg3NS4xNjc3MDUxOTk3*_ga_CW55HF8NVT*MTY5NzA5OTkwNy4zNi4xLjE2OTcwOTk5MzUuMzIuMC4w',
    // Add more image URLs as needed
  ];

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Container();
    }
    var camera = controller!.value;
    final size = MediaQuery.of(context).size;
    var scale = 0.0;
    try {
      scale = size.aspectRatio * camera.aspectRatio;
    } catch (e) {
      debugPrint(e.toString());
    }

    if (scale < 1) scale = 1 / scale;

    if (!controller!.value.isInitialized) {
      return Container();
    }
    return WillPopScope(
      onWillPop: () {
        if (panelController.status == SlidingUpPanelStatus.expanded) {
          panelController.hide();
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: !isProcessDone
          ? CircularProgressIndicator()
          : Stack(
              children: [
                Scaffold(
                  floatingActionButton: indexList.isNotEmpty
                      ? FloatingActionButton(
                          onPressed: () async {
                            for (var element in indexList) {
                              File file = await imageMedium
                                  .elementAt(element)
                                  .getFile();
                              setState(() {
                                results.add(file);
                              });
                            }
                            compress(results);
                          },
                          backgroundColor: Colors.greenAccent,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  body: Stack(
                    children: [
                      GestureDetector(
                        // onHorizontalDragStart: (detalis) {
                        //   panelController.expand();
                        //   //print(detalis.primaryVelocity);
                        // },
                        onVerticalDragStart: (e) {
                          panelController.expand();
                        },
                        child: Transform.scale(
                          scale: scale,
                          child: Center(
                            child: CameraPreview(controller!),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 250,
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              Expanded(
                                  child: Padding(
                                padding: EdgeInsets.only(
                                    left:
                                        MediaQuery.of(context).size.width * .8),
                                child: FloatingActionButton(
                                  onPressed: () {
                                    print("send!!!");
                                  },
                                  child: Icon(Icons.check),
                                ),
                              )),
                              SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: imageFromgallery.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          // isImageSelected = !isImageSelected;
                                          selectedImages[index]['selected'] =
                                              !selectedImages[index]
                                                  ['selected'];
                                          // selectedImages.add({
                                          //   'id': index,
                                          //   'imagePath': imageFromgallery[index],
                                          //   'selected': true,
                                          // });
                                        });
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Stack(
                                            alignment:
                                                AlignmentDirectional.center,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(.2),
                                                ),
                                                child: Image.file(
                                                  imageFromgallery[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              if (selectedImages[index]
                                                  ['selected'])
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(.2),
                                                  ),
                                                  child: Icon(
                                                    Icons.done,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                            ],
                                          )),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    (!kIsWeb)
                                        ? IconButton(
                                            onPressed: () async {
                                              final ImagePicker picker0 =
                                                  ImagePicker();
                                              if (!widget.isMultiple) {
                                                final XFile? image =
                                                    await picker0.pickImage(
                                                        source: ImageSource
                                                            .gallery);
                                                if (image == null) {
                                                  return;
                                                }
                                                File file = File(image.path);
                                                compress([file]);
                                              } else {
                                                final List<XFile> images =
                                                    await picker0
                                                        .pickMultiImage();
                                                if (images.isEmpty) {
                                                  return;
                                                }
                                                List<File> file = [];
                                                for (var element in images) {
                                                  file.add(File(element.path));
                                                }
                                                compress(file);
                                              }
                                            },
                                            icon: const Icon(Icons.file_open,
                                                size: 30, color: Colors.white))
                                        : Container(),
                                    InkWell(
                                      onTap: () async {
                                        XFile file2 =
                                            await controller!.takePicture();
                                        File file = File(file2.path);

                                        Uint8List dataFile =
                                            await file.readAsBytes();
                                        String fileName = DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString();
                                        await ImageGallerySaver.saveImage(
                                          dataFile,
                                          quality: 100,
                                          name: "$fileName.jpg",
                                        );

                                        //compress([file]);
                                        setState(() async {
                                          imageFromgallery = [];
                                          await loadImages();

                                          fillUpImagesList(imageFromgallery);
                                          selectedImages[0]["selected"] = true;
                                        });
                                      },
                                      child: Container(
                                        width: 75,
                                        height: 75,
                                        decoration: BoxDecoration(
                                            // color: Colors.white,
                                            borderRadius: const BorderRadius
                                                    .all(
                                                Radius.circular(
                                                    50) //                 <--- border radius here
                                                ),
                                            border: Border.all(
                                                color: Colors.white, width: 3)),
                                      ),
                                    ),
                                    (!kIsWeb && (cameras.length > 1))
                                        ? IconButton(
                                            onPressed: () {
                                              if (camIndex + 1 >=
                                                  cameras.length) {
                                                camIndex = 0;
                                              } else {
                                                camIndex++;
                                              }
                                              controller = CameraController(
                                                  cameras[camIndex],
                                                  ResolutionPreset.veryHigh);
                                              controller!
                                                  .initialize()
                                                  .then((_) {
                                                if (!mounted) {
                                                  return;
                                                }
                                                setState(() {});
                                              });
                                            },
                                            icon: const Icon(
                                                Icons.cameraswitch_outlined,
                                                size: 30,
                                                color: Colors.white))
                                        : Container()
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Align(
                            alignment: Alignment.topCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        flashOn = !flashOn;
                                        if (flashOn) {
                                          // controller!.setFlashMode(cameraaw.torch);
                                        } else {
                                          // controller!.setFlashMode(FlashMode.off);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.flash_off,
                                        size: 30, color: Colors.white)),
                                IconButton(
                                    onPressed: () {
                                      compress([]);
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                    ))
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  onSettingCallback() {
    setState(() {
      showPerformance = !showPerformance;
    });
  }

  compress(List<File> files) async {
    List<File> files2 = [];
    for (File file in files) {
      Uint8List? blobBytes = await testCompressFile(file);
      var dir = await getTemporaryDirectory();
      String trimmed = dir.absolute.path;
      String dateTimeString = DateTime.now().millisecondsSinceEpoch.toString();
      String pathString = "$trimmed/$dateTimeString.jpg";
      File fileNew = File(pathString);
      fileNew.writeAsBytesSync(List.from(blobBytes!));
      files2.add(fileNew);
    }
  }

  String dateTimeToString(DateTime dateTime, String pattern) {
    final format = DateFormat(pattern);
    return format.format(dateTime);
  }

  Future<Uint8List?> testCompressFile(File file) async {
    var decodedImage = await decodeImageFromList(file.readAsBytesSync());
    var result = await FlutterImageCompress.compressWithFile(file.absolute.path,
        minHeight: decodedImage.height,
        minWidth: decodedImage.width,
        quality: widget.compressionQuality!);
    return result;
  }
}
