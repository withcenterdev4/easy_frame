import 'package:easy_storage/easy_storage.dart';
import 'package:flutter/material.dart';

/// General Upload Icon Button
///
/// This widget is displaying an IconButton and is used to upload an image,
/// video, or file.
///
/// There are widgets that uses this widge to upload specific types of files:
/// [FileUploadIconButton], [ImageUploadIconButton], [VideoUploadIconButton].
///
/// The [onUpload] function is called when the upload is complete.
class UploadIconButton extends StatelessWidget {
  const UploadIconButton({
    super.key,
    required this.onUpload,
    this.onUploadSourceSelected,
    this.photoCamera = true,
    this.photoGallery = true,
    this.videoCamera = false,
    this.videoGallery = false,
    this.gallery = false,
    this.file = false,
    this.progress,
    this.complete,
    this.icon = const Icon(Icons.add),
    this.iconSize,
    this.visualDensity,
    this.iconPadding,
    this.uploadBottomSheetPadding,
    this.uploadBottomSheetSpacing,
  });

  final void Function(String url) onUpload;
  final void Function(SourceType?)? onUploadSourceSelected;

  final Widget icon;
  final Function(double)? progress;
  final Function()? complete;
  final VisualDensity? visualDensity;

  final bool photoCamera;
  final bool photoGallery;

  final bool videoCamera;
  final bool videoGallery;

  final bool gallery;
  final bool file;

  final double? iconSize;
  final EdgeInsetsGeometry? iconPadding;
  final EdgeInsetsGeometry? uploadBottomSheetPadding;
  final double? uploadBottomSheetSpacing;

  const UploadIconButton.file(
    this.onUpload, {
    super.key,
    this.onUploadSourceSelected,
    this.progress,
    this.complete,
    this.icon = const Icon(Icons.attach_file),
    this.iconSize,
    this.visualDensity,
    this.iconPadding,
    this.uploadBottomSheetPadding,
    this.uploadBottomSheetSpacing,
  })  : photoCamera = false,
        photoGallery = false,
        videoCamera = false,
        videoGallery = false,
        gallery = true,
        file = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      iconSize: iconSize,
      visualDensity: visualDensity,
      padding: iconPadding,
      onPressed: () async {
        final uploadedUrl = await StorageService.instance.upload(
          context: context,
          photoGallery: photoGallery,
          photoCamera: photoCamera,
          videoGallery: videoGallery,
          videoCamera: videoCamera,
          gallery: gallery,
          file: file,
          progress: progress,
          complete: complete,
          spacing: uploadBottomSheetSpacing ??
              StorageService.instance.uploadBottomSheetSpacing,
          padding: uploadBottomSheetPadding ??
              StorageService.instance.uploadBottomSheetPadding,
          onUploadSourceSelected: onUploadSourceSelected,
        );
        if (uploadedUrl != null) {
          onUpload.call(uploadedUrl);
        }
      },
    );
  }
}
