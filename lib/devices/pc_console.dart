import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/devices/pc_device.dart';

class PCConsole {
  final PCDevice pc;

  PCConsole(this.pc);

  String getPrompt() => "${pc.name}>";

  String processCommand(String input) {
    if (input.trim().isEmpty) return "";

    final args = input.trim().split(RegExp(r"\s+"));
    final cmd = args.first.toLowerCase();

    if (cmd == "ping" && args.length == 2) {
      return _ping(args[1]);
    }

    return "% Unknown command";
  }

  String _ping(String targetIP) {
    // same IP? skip
    if (targetIP == pc.ipAddress) {
      return "Cannot ping self.";
    }

    // check same subnet
    if (_sameSubnet(pc.ipAddress, targetIP, pc.subnetMask)) {
      final reachable = _traverseNetwork(pc.port, targetIP, {});
      if (reachable) {
        return "Reply from $targetIP: bytes=32 time<1ms TTL=64";
      } else {
        return "Destination host unreachable.";
      }
    }

    // if not same subnet, forward to default gateway
    if (pc.defaultGateway.isNotEmpty && pc.defaultGateway != "0.0.0.0") {
      final reachable = _traverseNetwork(pc.port, targetIP, {});
      if (reachable) {
        return "Reply from $targetIP: bytes=32 time<1ms TTL=64";
      } else {
        return "Destination host unreachable.";
      }
    }

    return "No route to host.";
  }
}

bool _sameSubnet(String ip1, String ip2, String mask) {
  int ip1Int = _ipToInt(ip1);
  int ip2Int = _ipToInt(ip2);
  int maskInt = _ipToInt(mask);
  return (ip1Int & maskInt) == (ip2Int & maskInt);
}

int _ipToInt(String ip) {
  final parts = ip.split(".").map(int.parse).toList();
  return (parts[0] << 24) |
         (parts[1] << 16) |
         (parts[2] << 8)  |
         (parts[3]);
}

bool _traverseNetwork(EthernetPort start, String targetIP, Set<EthernetPort> visited) {
  if (visited.contains(start)) return false;
  visited.add(start);

  // direct match on this port
  if (start.ipAddress == targetIP && start.isUp) return true;

  // connected PC
  if (start.connectedPC != null) {
    if (start.connectedPC!.ipAddress == targetIP) return true;
    if (_traverseNetwork(start.connectedPC!.port, targetIP, visited)) return true;
  }

  // connected Router (respect interfaces + static routes)
  if (start.connectedRouter != null) {
    final router = start.connectedRouter!;

    // 1) check directly connected ports on the router (hosts directly attached)
    for (final p in router.ports) {
      if (p.isUp) {
        if (p.ipAddress == targetIP) return true;
        if (p.connectedPC != null && p.connectedPC!.ipAddress == targetIP) return true;
      }
    }

    // 2) try interface-based forwarding (if router has an interface in same subnet as target)
    for (final p in router.ports) {
      if (p.isUp && p.ipAddress != null && p.subnetMask != null) {
        if (_sameSubnet(p.ipAddress!, targetIP, p.subnetMask!)) {
          if (_traverseNetwork(p, targetIP, visited)) return true;
        }
      }
    }

    // 3) respect static routes: find a router port that can reach the next-hop gateway
    for (final route in router.routingTable) {
      if (_sameSubnet(targetIP, route.destination, route.netmask)) {
        EthernetPort? gwPort;
        for (final p in router.ports) {
          if (p.isUp &&
              p.ipAddress != null &&
              p.subnetMask != null &&
              _sameSubnet(p.ipAddress!, route.gateway, p.subnetMask!)) {
            gwPort = p;
            break;
          }
        }
        if (gwPort != null && _traverseNetwork(gwPort, targetIP, visited)) return true;
      }
    }
  }

  // connected Switch (flood)
  if (start.connectedSwitch != null) {
    for (final p in start.connectedSwitch!.ports) {
      if (p.isUp && _traverseNetwork(p, targetIP, visited)) return true;
    }
  }

  return false;
}


