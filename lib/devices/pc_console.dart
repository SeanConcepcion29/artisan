import 'dart:math';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:flutter/foundation.dart';


class PCConsole {
  final PCDevice pc;

  PCConsole(this.pc);

  /* sets the prompt for pc CLI */
  String getPrompt() => "${pc.name}>";


  /* FUNCTION that reads and processes cli input to determine command to execute */
  String processCommand(String input) {
    if (input.trim().isEmpty) return "";

    final args = input.trim().split(RegExp(r"\s+"));
    final cmd = args.first.toLowerCase();

    if (cmd == "ping" && args.length >= 2) {
      return _ping(args);
    }
    
    else if (cmd == "clear") {
      pc.consoleHistory.clear();
      return "";
    }

    return "% Unknown command";
  }


  /* FUNCTION that performs the ping action */
  String _ping(List<String> args) {
    String targetIP = args[1];

    if (targetIP == pc.ipAddress) {
      return "Cannot ping self.";
    }

    int attempts = 5;
    int packetSize = 32;

    /*** PING OPTIONS ***/
    for (int i = 2; i < args.length; i++) {
      if (args[i] == "-n" && i + 1 < args.length) {
        attempts = int.tryParse(args[i + 1]) ?? attempts;
      }
      
      else if (args[i] == "-l" && i + 1 < args.length) {
        packetSize = int.tryParse(args[i + 1]) ?? packetSize;
      }
    }

    const int initialTTL = 64;
    final buffer = StringBuffer();
    final rand = Random();

    buffer.writeln("Pinging $targetIP with $packetSize bytes of data:");

    int received = 0;
    int lost = 0;
    final rtts = <int>[];

    /*** PING ACTION ***/
    for (int i = 0; i < attempts; i++) {

      /* records the start time where the ping propagation begins */
      final startTime = DateTime.now().microsecondsSinceEpoch;

      /* performs a recursive traversing of the network connection */
      final res = _traverseNetwork(pc.port, targetIP, {}, initialTTL, isFirstAttempt: i == 0);

      /* records the end time where the ping result is gathered */
      final endTime = DateTime.now().microsecondsSinceEpoch;
      int elapsedMs = ((endTime - startTime) / 1000).round();


      /*** PING REACHED ***/
      if (res == PingResult.reachable) {
        elapsedMs += rand.nextInt(3); 

        int ttlLeft = initialTTL - rand.nextInt(10);
        buffer.writeln(
            "Reply from $targetIP: bytes=$packetSize time=${elapsedMs}ms TTL=$ttlLeft");

        rtts.add(elapsedMs);
        received++;
      }
      
      /*** PING EXPIRED ***/
      else if (res == PingResult.ttlExpired) {
        buffer.writeln("Request timed out. (TTL expired)");
        lost++;
      }
      
      /*** PING UNREACHABLE ***/
      else {
        buffer.writeln("Destination host unreachable.");
        lost++;
      }
    }


    /*** STATS ***/
    int lossPercent = ((lost / attempts) * 100).round();
    buffer.writeln("");
    buffer.writeln("Ping statistics for $targetIP:");
    buffer.writeln(
        "    Packets: Sent = $attempts, Received = $received, Lost = $lost ($lossPercent% loss)");

    /* calculates average round-trip time */
    if (rtts.isNotEmpty) {
      int minRtt = rtts.reduce(min);
      int maxRtt = rtts.reduce(max);
      int avgRtt = rtts.reduce((a, b) => a + b) ~/ rtts.length;

      buffer.writeln(
          "    Minimum = ${minRtt}ms, Maximum = ${maxRtt}ms, Average = ${avgRtt}ms");
    }

    buffer.writeln("");
    return buffer.toString().trim();
  }
}

/* stores the result of the ping */
enum PingResult { reachable, unreachable, ttlExpired }


/* FUNCTION that determines if two of the ip addresses are of the same subnet */
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


/* FUNCTION that performs a recursive traversal on the network to determine if the target is reachable from the starting node */
PingResult _traverseNetwork(EthernetPort start, String targetIP, Set<EthernetPort> visited, int ttl, {bool isFirstAttempt = false}) {
  if (ttl <= 0) return PingResult.ttlExpired;
  if (visited.contains(start)) return PingResult.unreachable;
  visited.add(start);

  if (kDebugMode && isFirstAttempt) {
    final visitedStr = visited.map((p) => "${p.name}(${p.ipAddress ?? 'no-ip'})[${p.vlanId}]").join(" -> ");
    if (kDebugMode) { print("\nVISITED: $visitedStr"); }
    if (kDebugMode) { print("${start.id} - ${start.ipAddress}"); }
  }

  if (start.ipAddress == targetIP && start.isUp) {
    return PingResult.reachable;
  }


  /*** PC CONNECTED ***/
  if (start.connectedPC != null) {
    if (start.connectedPC!.ipAddress == targetIP && _sameSubnet(start.ipAddress!, targetIP, start.subnetMask!)) {
      return PingResult.reachable;
    }

    final res = _traverseNetwork(start.connectedPC!.port, targetIP, visited, ttl - 1, isFirstAttempt: isFirstAttempt,);
    if (res != PingResult.unreachable) return res;
  }


  /*** ROUTER CONNECTED ***/
  if (start.connectedRouter != null) {
    final router = start.connectedRouter!;

    /*** 1) check directly connected ports ***/
    for (final p in router.ports) {
      if (p.isUp && p.ipAddress != null && p.subnetMask != null) {
        if (p.ipAddress == targetIP && _sameSubnet(p.ipAddress!, targetIP, p.subnetMask!)) {
          return PingResult.reachable;
        }

        if (p.connectedPC != null && p.connectedPC!.ipAddress == targetIP && _sameSubnet(p.ipAddress!, targetIP, p.subnetMask!)) {
          return PingResult.reachable;
        }
      }
    }

    /*** 2) interface-based forwarding ***/
    for (final p in router.ports) {
      if (p.isUp && p.ipAddress != null && p.subnetMask != null) {
        if (_sameSubnet(p.ipAddress!, targetIP, p.subnetMask!)) {
          final res = _traverseNetwork(p, targetIP, visited, ttl - 1, isFirstAttempt: isFirstAttempt);
          if (res != PingResult.unreachable) return res;
        }
      }
    }

    /*** 3) static routes ***/
    for (final route in router.routingTable) {
      if (_sameSubnet(targetIP, route.destination, route.netmask)) {
        EthernetPort? gwPort;

        for (final p in router.ports) {
          if (p.isUp && p.ipAddress != null && p.subnetMask != null && _sameSubnet(p.ipAddress!, route.gateway, p.subnetMask!)) {
            gwPort = p;
            break;
          }
        }

        if (gwPort != null) {
          final res = _traverseNetwork(gwPort, targetIP, visited, ttl - 1, isFirstAttempt: isFirstAttempt);
          if (res != PingResult.unreachable) return res;
        }
      }
    }
  }

  
  /*** SWITCH CONNECTED ***/
  if (start.connectedSwitch != null) {
    final sw = start.connectedSwitch!;

    for (final port in sw.ports) {
      if (port == start || !port.isUp) continue;
      if (!port.allowsVlan(start.vlanId)) continue;

      final res = _traverseNetwork(port, targetIP, visited, ttl - 1, isFirstAttempt: isFirstAttempt);
      if (res != PingResult.unreachable) return res;
    }
  }

  return PingResult.unreachable;
}