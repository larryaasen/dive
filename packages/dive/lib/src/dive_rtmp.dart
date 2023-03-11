import 'package:collection/collection.dart' show IterableExtension;
import 'package:dive_obslib/dive_obslib.dart';

class DiveRTMPServices {
  final List<DiveRTMPService> services;

  const DiveRTMPServices(this.services);

  /// When [commonNamesOnly] is true (default) it collects only the common services, and when
  /// false it collects all services.
  factory DiveRTMPServices.standard({bool commonNamesOnly = true}) {
    final services = <DiveRTMPService>[];
    final serviceNames = obslib.streamOutputGetServiceNames(commonNamesOnly: commonNamesOnly);
    for (final serviceName in serviceNames) {
      final rtmpServers = <DiveRTMPServer>[];
      final servers = obslib.streamOutputGetServiceServers(serviceName: serviceName);
      for (var server in servers.keys) {
        rtmpServers.add(DiveRTMPServer(name: server, url: servers[server]));
      }
      services.add(DiveRTMPService(name: serviceName, servers: rtmpServers));
    }

    return DiveRTMPServices(services);
  }

  /// Returns the list of the streaming service names.
  List<String?> get serviceNames => services.map((service) => service.name).toList();

  /// Returns a service for the [serviceName] or null.
  DiveRTMPService? serviceForName(String serviceName) =>
      services.firstWhereOrNull((service) => service.name == serviceName);

  /// Returns the server list for a service.
  List<String?>? serviceServers(String serviceName) {
    final service = serviceForName(serviceName);
    if (service == null) return null;
    return service.serverNames;
  }

  @override
  String toString() {
    return "DiveRTMPServices: total: ${services.length}\nservices: $services\n";
  }
}

class DiveRTMPService {
  final String? name;
  final List<DiveRTMPServer>? servers;

  DiveRTMPService({this.name, this.servers});

  /// Returns the list of the service server names.
  List<String?> get serverNames => servers!.map((server) => server.name).toList();

  DiveRTMPServer? serverForName(String serverName) =>
      servers!.firstWhereOrNull((server) => server.name == serverName);

  @override
  String toString() {
    return "DiveRTMPService: name: $name, servers:\n$servers\n";
  }
}

class DiveRTMPServer {
  final String? name;
  final String? url;

  DiveRTMPServer({this.name, this.url});

  @override
  String toString() {
    return "DiveRTMPServer: name: $name, url: $url";
  }
}
