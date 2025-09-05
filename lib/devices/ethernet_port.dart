import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/switch_device.dart';

class EthernetPort {
  final String id; // e.g. "eth0", "eth1"

  PCDevice? connectedPC;
  RouterDevice? connectedRouter;
  SwitchDevice? connectedSwitch;

  EthernetPort({required this.id});

  bool get isFree =>
      connectedPC == null && connectedRouter == null && connectedSwitch == null;

  /* DISCONNECT PORT */
  void disconnect() {
    connectedPC = null;
    connectedRouter = null;
    connectedSwitch = null;
  }
}

/* CONNECT PC TO ROUTER */
bool connectPCToRouter(PCDevice pc, RouterDevice r1) {
  if (!pc.port.isFree) return false; // PC already in use

  final freePort = r1.getFreePort();
  if (freePort == null) return false; // Router has no free ports

  // Link both sides
  pc.port.connectedRouter = r1;
  freePort.connectedPC = pc;
  return true;
}

/* CONNECT ROUTER TO ROUTER */
bool connectRouterToRouter(RouterDevice r1, RouterDevice r2) {
  final p1 = r1.getFreePort();
  final p2 = r2.getFreePort();

  if (p1 != null && p2 != null) {
    p1.connectedRouter = r2;
    p2.connectedRouter = r1;
    return true;
  }
  return false;
}

/* CONNECT PC TO SWITCH */
bool connectPCToSwitch(PCDevice pc, SwitchDevice sw) {
  if (!pc.port.isFree) return false;

  final freePort = sw.getFreePort();
  if (freePort == null) return false;

  pc.port.connectedSwitch = sw;
  freePort.connectedPC = pc;
  return true;
}

/* CONNECT ROUTER TO SWITCH */
bool connectRouterToSwitch(RouterDevice r, SwitchDevice sw) {
  final rPort = r.getFreePort();
  final sPort = sw.getFreePort();

  if (rPort == null || sPort == null) return false;

  rPort.connectedSwitch = sw;
  sPort.connectedRouter = r;
  return true;
}

/* CONNECT SWITCH TO SWITCH */
bool connectSwitchToSwitch(SwitchDevice s1, SwitchDevice s2) {
  final p1 = s1.getFreePort();
  final p2 = s2.getFreePort();

  if (p1 != null && p2 != null) {
    p1.connectedSwitch = s2;
    p2.connectedSwitch = s1;
    return true;
  }
  return false;
}
