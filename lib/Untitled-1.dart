import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
  List<Album> imageAlbums = [];
  Set<Medium> imageMedium = {};
  Uint8List? bytes;
  List<File> results = [];
  List<int> indexList = [];
  int camIndex = 0;
  int pageIndex = 1;
  int pageCount = 10;
  int pageIndex2 = 1;
  int pageCount2 = 50;

  int count = 0;
  int count2 = 0;
  ScrollController bottomController = ScrollController();
  ScrollController topController = ScrollController();
  int scroll = 0;

  bool isImageSelected = false;
  bool isProcessDone = false;

  List<Map<String, dynamic>> selectedImages = [];

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

  void uploadImageToBRP_Mobile_Photo_Anomalies(context, File image) async {
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
  }

  bool hide = true;
  List<File> selectedImagesFromGallery = []; // List of selected image

  static int selectedImageCount = 0;
  Future<void> getImagesFromGalleryAndUpload() async {
    final pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 100, // To set quality of images
      maxHeight: 1000, // To set maxheight of images that you want in your app
      maxWidth: 1000, // To set maxheight of images that you want in your app
    );
    var length = 0;

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      selectedImagesFromGallery =
          pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();

      for (var img in selectedImagesFromGallery) {
        uploadImageToBRP_Mobile_Photo_Anomalies(context, img);
        setState(() {
          length++;
        });
      }
      //this for uploading the selected images from the camera screen 
      // for (var element in selectedImages) {
      //   uploadImageToBRP_Mobile_Photo_Anomalies(context, element["imagePath"]);
      //   setState(() {
      //     length++;
      //   });
      // }

      if (length == selectedImages.length + selectedImages.length) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is successfully updated')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No images selected')));
    }
  }

  late File recentImage;
  pickRecentPhoto() async {
    var Albums = await PhotoGallery.listAlbums(
      mediumType: MediumType.image,
    );
    Set<Medium> medium = {};
    for (var element in Albums) {
      var data = await element.listMedia();

      medium.addAll(data.items);
    }

    File file = await medium.toList()[0].getFile();
    recentImage = file;
    print("-- ${recentImage.path}");

    imageFromgallery.add(file);
    setState(() {});
  }

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
    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                // onHorizontalDragStart: (detalis) {
                //   panelController.expand();
                //   //print(detalis.primaryVelocity);
                // },

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
                            left: MediaQuery.of(context).size.width * .8,
                            top: MediaQuery.of(context).size.width * .02),
                        child: hide
                            ? null
                            : Stack(children: [
                                FloatingActionButton(
                                  backgroundColor: Colors.white,
                                  onPressed: () {
                                    int index = 0;
                                    print("send!!!");
                                    for (var img in selectedImages) {
                                      if (img["selected"] == true) {
                                        uploadImageToBRP_Mobile_Photo_Anomalies(
                                            context, img["imagePath"]);
                                      }
                                      index += 1;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Images is successfully updated')));
                                    if (index == selectedImages.length) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Icon(Icons.check),
                                ),
                                if (selectedImageCount > 0)
                                  Positioned(
                                    bottom: 60,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        selectedImageCount.toString(),
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ]),
                      )),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageFromgallery.length-1,
                          itemBuilder: (BuildContext context, int index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  // isImageSelected = !isImageSelected;
                                  selectedImages[index]['selected'] =
                                      !selectedImages[index]['selected'];
                                  // selectedImages.add({
                                  //   'id': index,
                                  //   'imagePath': imageFromgallery[index],
                                  //   'selected': true,
                                  // });
                                  if (selectedImages[index]['selected']) {
                                    selectedImageCount++;
                                  } else {
                                    selectedImageCount--;
                                  }
                                  for (var element in selectedImages) {
                                    if (element["selected"] == true) {
                                      hide = false;

                                      return;
                                    } else {
                                      hide = true;
                                    }
                                  }
                                });
                              },
                              child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Stack(
                                    fit: StackFit.passthrough,
                                    alignment: AlignmentDirectional.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(.2),
                                        ),
                                        child: Image.file(
                                          imageFromgallery[index],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (selectedImages[index]['selected'])
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              .17,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(.2),
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            (!kIsWeb)
                                ? IconButton(
                                    onPressed: () async {
                                      getImagesFromGalleryAndUpload().then(
                                        (value) {
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 35,
                                        color: Colors.white))
                                : Container(),
                            InkWell(
                              onTap: () async {
                                XFile file2 = await controller!.takePicture();
                                File file = File(file2.path);

                                Uint8List dataFile = await file.readAsBytes();
                                String fileName = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                                await ImageGallerySaver.saveImage(
                                  dataFile,
                                  quality: 100,
                                  name: "$fileName.jpg",
                                );

                                compress([file]);
                                setState(() async {
                                  pickRecentPhoto();
                                  imageFromgallery.insert(0, recentImage);
                                  selectedImages.insert(0, {
                                    'id': imageFromgallery.length,
                                    'imagePath': recentImage.path,
                                    'selected': true,
                                  });

                                  await loadImages();

                                  selectedImageCount++;
                                  for (var element in selectedImages) {
                                    if (element["selected"] == true) {
                                      hide = false;

                                      return;
                                    } else {
                                      hide = true;
                                    }
                                  }
                                });
                              },
                              child: Container(
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                    // color: Colors.white,
                                    borderRadius: const BorderRadius.all(
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
                                      if (camIndex + 1 >= cameras.length) {
                                        camIndex = 0;
                                      } else {
                                        camIndex++;
                                      }
                                      controller = CameraController(
                                          cameras[camIndex],
                                          ResolutionPreset.veryHigh);
                                      controller!.initialize().then((_) {
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
    );
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
