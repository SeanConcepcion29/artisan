import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';

class EthernetPort {
  final String id; // e.g. "eth0", "eth1"
  PCDevice? connectedPC;
  RouterDevice? connectedRouter;

  EthernetPort({required this.id});

  bool get isFree => connectedPC == null && connectedRouter == null;

  /// Connect this port to a PC
  void connectToPC(PCDevice pc) {
    connectedPC = pc;
    connectedRouter = null;
  }

  /// Connect this port to a Router
  void connectToRouter(RouterDevice router) {
    connectedRouter = router;
    connectedPC = null;
  }

  /// Disconnect this port
  void disconnect() {
    connectedPC = null;
    connectedRouter = null;
  }
}

/// Utility function: Connect a PC to a Router
bool connectPCToRouter(PCDevice pc, RouterDevice router) {
  if (!pc.port.isFree) return false; // PC already in use
  final freePort = router.getFreePort();
  if (freePort == null) return false; // Router has no free ports

  // Link both sides
  pc.port.connectedRouter = router;
  freePort.connectedPC = pc;
  return true;
}


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
