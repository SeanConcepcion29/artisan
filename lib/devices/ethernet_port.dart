import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/switch_device.dart';
import 'package:uuid/uuid.dart';


class EthernetPort {
  final String id;
  String name;

  /* determines if a port is free and/or active (up) */
  bool isFree = true;
  bool isUp = false;
  
  String? ipAddress;
  String? subnetMask;
  String? gateway;  

  PCDevice? connectedPC;
  RouterDevice? connectedRouter;
  SwitchDevice? connectedSwitch;

  /* creates a unique id for each port */
  static final Uuid _uuid = Uuid();
  EthernetPort({String? id, required this.name}) : id = id ?? _uuid.v4();

  /* FUNCTION that configures ip, subnet, gateway, and activeness of port */
  void assignIP(String ip, String mask, {String? gw}) {
    ipAddress = ip;
    subnetMask = mask;
    gateway = gw;
    isUp = false;
  }

  /* FUNCTION that toggles the port to be active */
  void noShutdown() {
    isUp = true;
  }

  /* FUNCTION that toggles the port to be inactive */
  void shutdown() {
    isUp = false;
  }

  /* FUNCTION that disconnects and resets port connections */
  void disconnect() {
    connectedPC = null;
    connectedRouter = null;
    connectedSwitch = null;
    isFree = true;
    isUp = false;
    ipAddress = null;
    subnetMask = null;
    gateway = null;
  }

  /* seriliazes port configurations */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isFree': isFree,
      'isUp': isUp,
      'ipAddress': ipAddress,
      'subnetMask': subnetMask,
      'gateway': gateway,
      'name': name,
    };
  }

  /* deseriliazes port configurations */
  factory EthernetPort.fromMap(Map<String, dynamic> map) {
    final port = EthernetPort(
      id: map['id'],
      name: map['name'] ?? 'EthernetPort',
    );
    port.isFree = map['isFree'] ?? true;
    port.isUp = map['isUp'] ?? false;
    port.ipAddress = map['ipAddress'];
    port.subnetMask = map['subnetMask'];
    port.gateway = map['gateway'];
    return port;
  }

  /* loads port configuration */
  void applyFromMap(Map<String, dynamic> map) {
    isUp = map['isUp'] ?? false;
    ipAddress = map['ipAddress'];
    subnetMask = map['subnetMask'];
    gateway = map['gateway'];
  }
}


/*FUNCTION that connects pc to router */
bool connectPCToRouter(PCDevice pc, RouterDevice r1) {
  if (!pc.port.isFree) return false;
  final freePort = r1.getFreePort();
  if (freePort == null) return false; 

  pc.port.isFree = false;
  pc.port.connectedRouter = r1;

  freePort.isFree = false;
  freePort.connectedPC = pc;

  return true;
}


/*FUNCTION that connects router to router */
bool connectRouterToRouter(RouterDevice r1, RouterDevice r2) {
  final p1 = r1.getFreePort();
  final p2 = r2.getFreePort();

  if (p1 != null && p2 != null) {
    p1.isFree = false;
    p2.isFree = false;

    p1.connectedRouter = r2;
    p2.connectedRouter = r1;

    return true;
  }
  return false;
}


/*FUNCTION that connects pc to switch */
bool connectPCToSwitch(PCDevice pc, SwitchDevice sw) {
  if (!pc.port.isFree) return false;
  final freePort = sw.getFreePort();
  if (freePort == null) return false;

  pc.port.isFree = false;
  pc.port.connectedSwitch = sw;
  pc.port.isUp = true; 

  freePort.isFree = false;
  freePort.connectedPC = pc;
  freePort.isUp = true;

  return true;
}


/*FUNCTION that connects router to switch */
bool connectRouterToSwitch(RouterDevice r, SwitchDevice sw) {
  final rPort = r.getFreePort();
  final sPort = sw.getFreePort();

  if (rPort == null || sPort == null) return false;

  rPort.isFree = false;
  sPort.isFree = false;

  rPort.connectedSwitch = sw;
  sPort.connectedRouter = r;

  rPort.isUp = true;
  sPort.isUp = true; 

  return true;
}


/*FUNCTION that connects switch to switch */
bool connectSwitchToSwitch(SwitchDevice s1, SwitchDevice s2) {
  final p1 = s1.getFreePort();
  final p2 = s2.getFreePort();

  if (p1 != null && p2 != null) {
    p1.isFree = false;
    p2.isFree = false;

    p1.connectedSwitch = s2;
    p2.connectedSwitch = s1;

    p1.isUp = true;
    p2.isUp = true;

    return true;
  }
  
  return false;
}
