import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; // Required for rootBundle

class MaskDetector {
  late tfl.Interpreter _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
    // Load model and labels
    _interpreter = await tfl.Interpreter.fromAsset('assets/model_unquant.tflite');
    _labels = await _loadLabels('assets/labels.txt');
    print("TFLite Model loaded successfully!");
  }

  // Future<List<String>> _loadLabels(String path) async {
  //   final labelsData = await DefaultAssetBundle.of().loadString(path);
  //   return labelsData.split('\n');
  // }
Future<List<String>> _loadLabels(String path) async {
  final labelsData = await rootBundle.loadString(path);
  return labelsData.split('\n');
}
  Future<String> runModel(img.Image image) async {
    // Resize image to match model input size (e.g., 224x224)
    final inputImage = img.copyResize(image, width: 224, height: 224);

    // Convert to ByteBuffer
    var input = imageToByteListFloat32(inputImage, 224);
    var output = List.filled(2, 0).reshape([1, 2]);

    // Run inference
    _interpreter.run(input, output);

    // Get label with the highest confidence
    final maskScore = output[0][1]; // Mask
    final noMaskScore = output[0][0]; // No Mask
    return maskScore > noMaskScore ? _labels[1] : _labels[0];
  }

  // Convert image to ByteBuffer for input
  static List<List<List<List<double>>>> imageToByteListFloat32(
    img.Image image, int size) {
  List<List<List<List<double>>>> input = List.generate(
    1,
    (i) => List.generate(
      size,
      (y) => List.generate(
        size,
        (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r / 255.0, // Red channel
            pixel.g / 255.0, // Green channel
            pixel.b / 255.0, // Blue channel
          ];
        },
      ),
    ),
  );
  return input;
}



  void close() {
    _interpreter.close();
  }
}
