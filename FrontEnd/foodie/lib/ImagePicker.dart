import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foodie/CustomDialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';

const Color kErrorRed = Colors.redAccent;
const Color kDarkGray = Color(0xFFA3A3A3);
const Color kLightGray = Color(0xFFF1F0F5);

enum PhotoSource { FILE, NETWORK }

class ImagePickerWidget extends StatefulWidget {
  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  XFile? _photos;
  String? _photoUrl;
  PhotoSource? _photoSource;
  //List<GalleryItem> _galleryItems = [];

  @override
  Widget build(BuildContext context) {
    if (_photos == null) {
      return _buildAddPhoto();
    }
    return InkWell(
      child: Image.file(File(_photos!.path)),
      );
    // return Scaffold(
    //   body: Column(
    //     crossAxisAlignment: CrossAxisAlignment.stretch,
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: <Widget>[
    //       Container(
    //         height: 100,
    //         child: ListView.builder(
    //           scrollDirection: Axis.horizontal,
    //           itemCount: _photos.length + 1,
    //           itemBuilder: (context, index) {
    //             if (index == 0) {
    //               return _buildAddPhoto();
    //             }
    //             XFile image = _photos[index - 1];
    //             PhotoSource source = _photosSources[index - 1];
    //             return Stack(
    //               children: <Widget>[
    //                 InkWell(
    //                   child: Container(
    //                     margin: EdgeInsets.all(5),
    //                     height: 100,
    //                     width: 100,
    //                     color: kLightGray,
    //                     child: source == PhotoSource.FILE
    //                         ? Image.file(File(image.path))
    //                         : Image.network(_photosUrls[index - 1]),
    //                   ),
    //                 ),
    //               ],
    //             );
    //           },
    //         ),
    //       ),
    //       // Container(
    //       //   margin: EdgeInsets.all(16),
    //       //   child: RaisedButton(
    //       //     child: Text('Save'),
    //       //     onPressed: () {},
    //       //   ),
    //       // )
    //     ],
    //   ),
    // );
  }

  _showOpenAppSettingsDialog(context) {
    return CustomDialog.show(
      context,
      'Permission needed',
      'Photos permission is needed to select photos',
      'Open settings',
      openAppSettings,
    );
  }

  _buildAddPhoto() {
    return InkWell(
      onTap: () => _onAddPhotoClicked(context),
      child: Container(
        margin: EdgeInsets.all(5),
        height: 100,
        width: 100,
        color: kDarkGray,
        child: Center(
          child: Icon(
            Icons.add_to_photos,
            color: kLightGray,
          ),
        ),
      ),
    );
  }

  _onAddPhotoClicked(context) async {
    Permission permission;

    if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      permission = Permission.storage;
    }

    PermissionStatus permissionStatus = await permission.status;

    print(permissionStatus);

    if (permissionStatus == PermissionStatus.restricted) {
      _showOpenAppSettingsDialog(context);

      permissionStatus = await permission.status;

      if (permissionStatus != PermissionStatus.granted) {
        //Only continue if permission granted
        return;
      }
    }

    if (permissionStatus == PermissionStatus.permanentlyDenied) {
      _showOpenAppSettingsDialog(context);

      permissionStatus = await permission.status;

      if (permissionStatus != PermissionStatus.granted) {
        //Only continue if permission granted
        return;
      }
    }

    // if (permissionStatus == PermissionStatus.undetermined) {
    //   permissionStatus = await permission.request();

    //   if (permissionStatus != PermissionStatus.granted) {
    //     //Only continue if permission granted
    //     return;
    //   }
    // }

    if (permissionStatus == PermissionStatus.denied) {
      if (Platform.isIOS) {
        _showOpenAppSettingsDialog(context);
      } else {
        permissionStatus = await permission.request();
      }

      if (permissionStatus != PermissionStatus.granted) {
        //Only continue if permission granted
        return;
      }
    }

    if (permissionStatus == PermissionStatus.granted) {
      print('Permission granted');
      XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        String fileExtension = p.extension(image.path);

        // _galleryItems.add(
        //   GalleryItem(
        //     id: Uuid().v1(),
        //     resource: image.path,
        //     isSvg: fileExtension.toLowerCase() == ".svg",
        //   ),
        // );

        setState(() {
          _photos = image;
          _photoSource = PhotoSource.FILE;
        });
      }
    }
  }
}

class GalleryItem {
  GalleryItem({this.id, this.resource, this.isSvg = false});

  final String? id;
  String? resource;
  final bool isSvg;
}
