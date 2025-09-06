import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/switch_device.dart';

class EthernetPort {
  final String id;

  bool isFree = true;
  bool isUp = false;
  
  String? ipAddress;
  String? subnetMask;

  PCDevice? connectedPC;
  RouterDevice? connectedRouter;
  SwitchDevice? connectedSwitch;

  EthernetPort({required this.id});

  void assignIP(String ip, String mask) {
    ipAddress = ip;
    subnetMask = mask;
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

  freePort.isFree = false;
  freePort.connectedPC = pc;

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
    return true;
  }
  return false;
}
