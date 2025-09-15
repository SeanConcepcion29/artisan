import 'dart:math';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:flutter/foundation.dart';


class PCConsole {
  final PCDevice pc;

  PCConsole(this.pc);

  String getPrompt() => "${pc.name}>";

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
      final res = _traverseNetwork(pc.port, targetIP, {}, initialTTL, isFirstAttempt: i == 0);


      /*
      // Simulate random packet loss (5% chance) /////////////////////////
      if (rand.nextDouble() < 0.05) {
        buffer.writeln("Request timed out.");
        lost++;
        continue;
      }
      */


      if (res == PingResult.reachable) {
        int rtt = _simulateRTT(rand);
        int ttlLeft = initialTTL - rand.nextInt(10); 

        buffer.writeln(
            "Reply from $targetIP: bytes=$packetSize time=${rtt}ms TTL=$ttlLeft");
        rtts.add(rtt);
        received++;
      }
      
      else if (res == PingResult.ttlExpired) {
        buffer.writeln("Request timed out. (TTL expired)");
        lost++;
      }
      
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

    if (rtts.isNotEmpty) {
      int minRtt = rtts.reduce(min);
      int maxRtt = rtts.reduce(max);
      int avgRtt = rtts.reduce((a, b) => a + b) ~/ rtts.length;

      buffer.writeln("Approximate round trip times in milli-seconds:");
      buffer.writeln(
          "    Minimum = ${minRtt}ms, Maximum = ${maxRtt}ms, Average = ${avgRtt}ms");
    }

    buffer.writeln("");
    return buffer.toString().trim();


  }
}


/* RANDOM SIMULATOR */
int _simulateRTT(Random rand) {
  return 1 + rand.nextInt(30);
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


PingResult _traverseNetwork(EthernetPort start, String targetIP, Set<EthernetPort> visited, int ttl, {bool isFirstAttempt = false}) {
  if (ttl <= 0) return PingResult.ttlExpired;
  if (visited.contains(start)) return PingResult.unreachable;
  visited.add(start);

  if (kDebugMode && isFirstAttempt) {
    final visitedStr = visited.map((p) => "${p.name}(${p.ipAddress ?? 'no-ip'})").join(" -> ");
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
    for (final p in start.connectedSwitch!.ports) {
      if (p.isUp && p != start) {
        String? otherIp;
        String? otherMask;

        if (p.connectedPC != null && p.connectedPC?.port.ipAddress == targetIP) {
          return PingResult.reachable;
        }
        
        else if (p.connectedRouter != null) {
          final router = p.connectedRouter!;

          for (final rPort in router.ports) {
            if (rPort.connectedSwitch == start.connectedSwitch) {
              otherIp = rPort.ipAddress;
              otherMask = rPort.subnetMask;
              break;
            }
          }
        }

        if (start.ipAddress != null && start.subnetMask != null && otherIp != null && otherMask != null) {
          if (_sameSubnet(start.ipAddress!, otherIp, start.subnetMask!)) {
            final res = _traverseNetwork(p,targetIP, visited, ttl, isFirstAttempt: isFirstAttempt);
            if (res != PingResult.unreachable) return res;
          }
        }
      }
    }
  }

  return PingResult.unreachable;
}
