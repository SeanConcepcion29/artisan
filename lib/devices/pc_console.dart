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
    if (targetIP == pc.ipAddress) {
      return "Cannot ping self.";
    }

    const int initialTTL = 5; // only allow 5 hops
    const int attempts = 5;   // number of echo requests
    int received = 0;

    final buffer = StringBuffer();

    for (int i = 0; i < attempts; i++) {
      final forward = _traverseNetwork(pc.port, targetIP, {}, initialTTL);

      if (forward == PingResult.reachable) {
        // ✅ check if the target can reply back
        final reply =
            _traverseNetwork(pc.port, pc.ipAddress, {}, initialTTL);
        if (reply == PingResult.reachable) {
          buffer.writeln(
              "Reply from $targetIP: bytes=32 time<1ms TTL=$initialTTL");
          received++;
        } else {
          buffer.writeln("Request timed out. (no reply)");
        }
      } else if (forward == PingResult.ttlExpired) {
        buffer.writeln("Request timed out. (TTL expired)");
      } else {
        buffer.writeln("Destination host unreachable.");
      }
    }

    int lost = attempts - received;
    int lossPercent = ((lost / attempts) * 100).round();

    buffer.writeln("");
    buffer.writeln("Ping statistics for $targetIP:");
    buffer.writeln(
        "    Packets: Sent = $attempts, Received = $received, Lost = $lost ($lossPercent% loss)");
    buffer.writeln("");
    return buffer.toString().trim();
  }
}

enum PingResult { reachable, unreachable, ttlExpired }

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
      (parts[2] << 8) |
      (parts[3]);
}

PingResult _traverseNetwork(
    EthernetPort start, String targetIP, Set<EthernetPort> visited, int ttl) {
  if (ttl <= 0) return PingResult.ttlExpired;
  if (visited.contains(start)) return PingResult.unreachable;
  visited.add(start);

  // direct match on this port
  if (start.ipAddress == targetIP && start.isUp) {
    return PingResult.reachable;
  }

  // connected PC
  if (start.connectedPC != null) {
    if (start.connectedPC!.ipAddress == targetIP) {
      return PingResult.reachable;
    }
    final res =
        _traverseNetwork(start.connectedPC!.port, targetIP, visited, ttl);
    if (res != PingResult.unreachable) return res;
  }

  // connected Router
  if (start.connectedRouter != null) {
    final router = start.connectedRouter!;

    // 1) check directly connected ports
    for (final p in router.ports) {
      if (p.isUp) {
        if (p.ipAddress == targetIP) return PingResult.reachable;
        if (p.connectedPC != null &&
            p.connectedPC!.ipAddress == targetIP) {
          return PingResult.reachable;
        }
      }
    }

    // 2) interface-based forwarding
    for (final p in router.ports) {
      if (p.isUp && p.ipAddress != null && p.subnetMask != null) {
        if (_sameSubnet(p.ipAddress!, targetIP, p.subnetMask!)) {
          final res =
              _traverseNetwork(p, targetIP, visited, ttl - 1); // TTL dec here
          if (res != PingResult.unreachable) return res;
        }
      }
    }

    // 3) static routes
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
        if (gwPort != null) {
          final res =
              _traverseNetwork(gwPort, targetIP, visited, ttl - 1); // TTL dec
          if (res != PingResult.unreachable) return res;
        }
      }
    }
  }

  // connected Switch (no TTL decrement)
  if (start.connectedSwitch != null) {
    for (final p in start.connectedSwitch!.ports) {
      if (p.isUp && p != start) { // 🚀 skip incoming port
        final res = _traverseNetwork(p, targetIP, visited, ttl);
        if (res != PingResult.unreachable) return res;
      }
    }
  }

  return PingResult.unreachable;
}
