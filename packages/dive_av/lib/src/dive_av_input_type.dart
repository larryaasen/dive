// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: avoid_print

/// An input type.
class DiveAVInputType {
  /// Creates an input type.
  DiveAVInputType(
      {this.localizedName,
      required this.uniqueID,
      required this.typeId,
      required this.locationID,
      required this.vendorID,
      required this.productID});

  /// The input name, such as `FaceTime HD Camera (Built-in)`.
  final String? localizedName;

  /// The input id, such as `0x8020000005ac8514`.
  final String uniqueID;

  /// The input type id, such as `video` or `audio`.
  final String typeId;

  final int locationID;
  final int vendorID;
  final int productID;

  static DiveAVInputType? fromMap(dynamic map) {
    final uniqueID = map['uniqueID'] as String?;
    final localizedName = map['localizedName'] as String?;
    final typeId = map['typeId'] as String?;
    if (uniqueID != null && localizedName != null && typeId != null) {
      final (locationID, vendorID, productID) = parseUniqueID(uniqueID);
      return DiveAVInputType(
        uniqueID: uniqueID,
        typeId: typeId,
        localizedName: localizedName,
        locationID: locationID,
        vendorID: vendorID,
        productID: productID,
      );
    }
    return null;
  }

  static (int locationID, int vendorID, int productID) parseUniqueID(
      String uniqueID) {
    if (!uniqueID.toLowerCase().startsWith('0x')) return (0, 0, 0);

    try {
      uniqueID = uniqueID.substring(2);
      if (uniqueID.length < 8) return (0, 0, 0);
      final product = uniqueID.substring(uniqueID.length - 4);
      final productID = int.parse(product, radix: 16);
      final vendor =
          uniqueID.substring(uniqueID.length - 8, uniqueID.length - 4);
      final vendorID = int.parse(vendor, radix: 16);
      final location = uniqueID.substring(0, uniqueID.length - 8);
      final locationID = int.parse(location, radix: 16);

      return (locationID, vendorID, productID);
    } catch (e) {
      print('dive_av: invalid uniqueID: $uniqueID, $e');
    }
    return (0, 0, 0);
    // try {
    //   // 0x21100015320e05
    //   // "0xLLLLLLLLVVVVPPPP"
    //   final regex = RegExp(r'0x(?<L>.{.+?})(?<V>.{4})(?<P>.{4})');

    //   final match = regex.firstMatch(uniqueID);
    //   if (match != null) {
    //     final locationID = int.parse(match.group(1)!, radix: 16);
    //     final vendorID = int.parse(match.group(2)!, radix: 16);
    //     final productID = int.parse(match.group(3)!, radix: 16);
    //     return (locationID, vendorID, productID);
    //   } else {
    //     print('dive_av: invalid uniqueID: $uniqueID');
    //     return (0, 0, 0);
    //   }
    // } catch (e) {
    //   print('dive_av: invalid uniqueID: $uniqueID, $e');
    //   return (0, 0, 0);
    // }
  }

  /* In the case of video devices, the AVCaptureDevice uniqueID seems to a string in the
  form "0xLLLLLLLLVVVVPPPP", where:

    LLLLLLLL is the hexadecimal string representing the USB device's location ID
    VVVV is the hexadecimal string representing the USB device's manufacturer ID
    PPPP is the hexadecimal string representing the USB device's product ID.
    e.g. 0x144000002E1A4C01  
  */

  @override
  String toString() {
    return "DiveAVInputType name: $uniqueID, id: $localizedName, typeId: $typeId";
  }
}
