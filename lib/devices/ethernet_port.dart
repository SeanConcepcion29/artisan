import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';

class EthernetPort {
  final String id; // e.g. "eth0", "eth1"
  
  PCDevice? connectedPC;
  RouterDevice? connectedRouter;

  EthernetPort({required this.id});

  bool get isFree => connectedPC == null && connectedRouter == null;


  /* DISCONNECT PORT */
  void disconnect() {
    connectedPC = null;
    connectedRouter = null;
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
