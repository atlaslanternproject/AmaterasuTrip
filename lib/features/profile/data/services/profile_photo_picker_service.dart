import 'package:image_picker/image_picker.dart';

class ProfilePhotoPickerService {
  ProfilePhotoPickerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<XFile?> pickFromGallery() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
  }

  Future<XFile?> pickFromCamera() {
    return _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 90);
  }

  Future<XFile?> retrieveLostPhoto() async {
    final response = await _imagePicker.retrieveLostData();

    if (response.isEmpty) {
      return null;
    }

    final files = response.files;

    if (files != null && files.isNotEmpty) {
      return files.first;
    }

    return response.file;
  }
}
