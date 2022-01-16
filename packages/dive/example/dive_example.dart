import 'package:dive/dive.dart';
import 'package:dive/src/dive_engine.dart';

void main() {
  runDiveApp();

  DiveLog.message('Dive Example - Image');

  DiveExample().run();
}

class DiveExample {
  void run() {
    const filename = '/Users/larry/Downloads/IMG_8384.jpg';
    final properties = DiveCoreProperties.fromMap(
        {DiveImageInputProvider.PROPERTY_FILENAME: filename});

    final imageProvider = DiveImageInputProvider();
    final imageSource = imageProvider.create("image1", properties);

    if (imageSource != null) {
      final compositing = DiveCompositingEngine(
          name: 'composite1', frameInput: imageSource.frameOutput);
      compositing.start();

      final output1 = DiveOutputLogger(
          name: 'output1', frameInput: compositing.frameOutput);
      output1.start();
      Future.delayed(Duration(seconds: 2), () {
        final output2 = DiveOutputLogger(
            name: 'output2', frameInput: imageSource.frameOutput);
        output2.start();

        Future.delayed(Duration(seconds: 2), () {
          final output3 = DiveOutputLogger(
              name: 'output3', frameInput: imageSource.frameOutput);
          final output4 = DiveOutputLogger(
              name: 'output4', frameInput: imageSource.frameOutput);
          output3.start();
          output4.start();

          const url =
              'https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg';

          final properties2 = DiveCoreProperties()
            ..setString(DiveImageInputProvider.PROPERTY_URL, url);

          final imageProvider2 = DiveImageInputProvider();
          final imageSource2 = imageProvider2.create("image2", properties2);
          if (imageSource2 != null) {
            final output5 = DiveOutputLogger(
                name: 'output5', frameInput: imageSource2.frameOutput);
            output5.start();
          }
        });
      });
    }
  }
}
