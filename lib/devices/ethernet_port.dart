import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/switch_device.dart';

import 'package:uuid/uuid.dart';

class EthernetPort {
  final String id;
  String name;

  bool isFree = true;
  bool isUp = false;
  
  String? ipAddress;
  String? subnetMask;
  String? gateway;  

  PCDevice? connectedPC;
  RouterDevice? connectedRouter;
  SwitchDevice? connectedSwitch;

  static final Uuid _uuid = Uuid();

  EthernetPort({String? id, required this.name}) : id = id ?? _uuid.v4();

  void assignIP(String ip, String mask, {String? gw}) {
    ipAddress = ip;
    subnetMask = mask;
    gateway = gw;
    // stays DOWN until explicitly noShutdown()
    isUp = false;
  }

  void noShutdown() {
    isUp = true;
  }

  void shutdown() {
    isUp = false;
  }

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

  void applyFromMap(Map<String, dynamic> map) {
    isUp = map['isUp'] ?? false;
    ipAddress = map['ipAddress'];
    subnetMask = map['subnetMask'];
    gateway = map['gateway'];
  }
}

/*** CONNECT PC TO ROUTER ***/
bool connectPCToRouter(PCDevice pc, RouterDevice r1) {
  if (!pc.port.isFree) return false;
  final freePort = r1.getFreePort();
  if (freePort == null) return false; 

  pc.port.isFree = false;
  pc.port.connectedRouter = r1;

  freePort.isFree = false;
  freePort.connectedPC = pc;

  // stays DOWN until manually noShutdown()
  return true;
}

/*** CONNECT ROUTER TO ROUTER ***/
bool connectRouterToRouter(RouterDevice r1, RouterDevice r2) {
  final p1 = r1.getFreePort();
  final p2 = r2.getFreePort();

  if (p1 != null && p2 != null) {
    p1.isFree = false;
    p2.isFree = false;

    p1.connectedRouter = r2;
    p2.connectedRouter = r1;

    // stays DOWN until manually noShutdown()
    return true;
  }
  return false;
}

/*** CONNECT PC TO SWITCH ***/
bool connectPCToSwitch(PCDevice pc, SwitchDevice sw) {
  if (!pc.port.isFree) return false;
  final freePort = sw.getFreePort();
  if (freePort == null) return false;

  pc.port.isFree = false;
  pc.port.connectedSwitch = sw;
  pc.port.isUp = true; // PC side UP because it's on a switch

  freePort.isFree = false;
  freePort.connectedPC = pc;
  freePort.isUp = true; // switch side UP too

  return true;
}

/*** CONNECT ROUTER TO SWITCH ***/
bool connectRouterToSwitch(RouterDevice r, SwitchDevice sw) {
  final rPort = r.getFreePort();
  final sPort = sw.getFreePort();

  if (rPort == null || sPort == null) return false;

  rPort.isFree = false;
  sPort.isFree = false;

  rPort.connectedSwitch = sw;
  sPort.connectedRouter = r;

  rPort.isUp = true; // router side UP because connected to switch
  sPort.isUp = true; // switch side UP

  return true;
}

/*** CONNECT SWITCH TO SWITCH ***/
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
