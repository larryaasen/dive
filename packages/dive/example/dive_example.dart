import 'package:dive/dive.dart';

void main() {
  runDiveApp();
  DiveLog.message('Dive Example - Image');
  DiveExample().run();
}

class DiveExample {
  void run() {
    final imageProvider = DiveImageInputProvider();
    final imageSource1 = imageProvider.create(
        "image1",
        DiveCoreProperties.fromMap({
          DiveImageInputProvider.PROPERTY_RESOURCE_NAME: 'assets/image1.jpg'
        }));

    final imageSource2 = imageProvider.create(
        "image2",
        DiveCoreProperties.fromMap({
          DiveImageInputProvider.PROPERTY_RESOURCE_NAME: 'assets/image1.jpg'
        }));

    if (imageSource1 != null && imageSource2 != null) {
      final compositing = DiveCompositingEngine(
          name: 'composite1',
          frameInput1: imageSource1.frameOutput,
          frameInput2: imageSource2.frameOutput);
      compositing.start();

      final output1 = DiveOutputLogger(
          name: 'output1', frameInput: compositing.frameOutput);
      output1.start();
      Future.delayed(const Duration(seconds: 2), () {
        final output2 = DiveOutputLogger(
            name: 'output2', frameInput: imageSource1.frameOutput);
        output2.start();

        Future.delayed(const Duration(seconds: 2), () {
          final output3 = DiveOutputLogger(
              name: 'output3', frameInput: imageSource1.frameOutput);
          final output4 = DiveOutputLogger(
              name: 'output4', frameInput: imageSource1.frameOutput);
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
