import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryModalBottomSheet extends StatefulWidget {
  @override
  _GalleryModalBottomSheetState createState() => _GalleryModalBottomSheetState();
}

class _GalleryModalBottomSheetState extends State<GalleryModalBottomSheet> {
  List<File> selectedImages = [];
  List<File> imagesFromGallery = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    // Request permission to access the gallery
    //bool isPermissionGranted = await PhotoManager.re();

    // if (!isPermissionGranted) {
    //   // Handle permission not granted
    //   return;
    // }

    // Load all the asset paths from the gallery
    List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(onlyAll: true);

    for (var path in paths) {
      // Fetch all the assets in the current path
      List<AssetEntity> assets = await path.getAssetListRange(start: 0, end: 20);

      for (var asset in assets) {
        // Fetch the file associated with the asset
        File? file = await asset.file;
        if (file != null && file.path.toLowerCase().endsWith(".jpg")) {
          // Add the file to the imagesFromGallery list
          setState(() {
            imagesFromGallery.add(file);
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            title: Text('Selected Images (${selectedImages.length})'),
            trailing: IconButton(
              icon: Icon(Icons.done),
              onPressed: () {
                // Close the bottom sheet and pass the selected images back
                Navigator.pop(context, selectedImages);
              },
            ),
          ),
          Divider(),
          isLoading
              ? CircularProgressIndicator() // Show loading indicator while images are being fetched
              : Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: imagesFromGallery.length,
                    itemBuilder: (context, index) {
                      File image = imagesFromGallery[index];
                      bool isSelected = selectedImages.contains(image);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedImages.remove(image);
                            } else {
                              selectedImages.add(image);
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            Image.file(image, fit: BoxFit.cover),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// Usage example:
void openGalleryModalBottomSheet(BuildContext context) async {
  List<File>? selectedImages = await showModalBottomSheet<List<File>>(
    context: context,
    builder: (context) => GalleryModalBottomSheet(),
  );

  if (selectedImages != null) {
    // Do something with the selected images
    for (var image in selectedImages) {
      print('Selected image: ${image.path}');
    }
  }
}