import 'package:artisan/devices/ethernet_port.dart';
import 'router_device.dart';


/* handles the different mode of router access */
enum RouterMode { user, privileged, globalConfig, interfaceConfig }


class RouterConsole {
  final RouterDevice router;

  RouterMode _mode = RouterMode.user;
  EthernetPort? _activeInterface;

  RouterConsole(this.router);

  /* sets the prompt for router CLI */
  String getPrompt() {
    switch (_mode) {
      case RouterMode.user:
        return "${router.name}>";
      case RouterMode.privileged:
        return "${router.name}#";
      case RouterMode.globalConfig:
        return "${router.name}(config)#";
      case RouterMode.interfaceConfig:
        return "${router.name}(config-if)#";
    }
  }

  /* FUNCTION that reads and processes cli input to determine command to execute */
  String processCommand(String input) {
    if (input.trim().isEmpty) return "";

    final args = input.trim().split(RegExp(r"\s+"));
    final cmd = args.first.toLowerCase();

    switch (_mode) {

      /*** USER MODE ***/
      case RouterMode.user:
        if (cmd == "enable") {
          _mode = RouterMode.privileged;
          return "";
        }
        
        else if (cmd == "clear") {
          router.consoleHistory.clear();
          return "";
        }

      return "% Invalid input at '${args.join(" ")}'";



      /*** PRIVILEGED MODE ***/
      case RouterMode.privileged:
        if (cmd == "configure" && args.length >= 2 && args[1].toLowerCase() == "terminal") {
          _mode = RouterMode.globalConfig;
          return "";
        }
        
        else if (cmd == "show" && args.length >= 2 && args[1] == "ip") {
          if (args.length >= 3 && args[2] == "route") {
            return _showIPRoutes();
          }
          return _showIP();
        }
        
        else if (cmd == "show" && args.length >= 2 && args[1].toLowerCase() == "connections") {
          return _showConnections();
        }
        
        else if (cmd == "copy" && args.length == 3 && args[1] == "running-config" && args[2] == "startup-config") {
          router.saveConfig();
          return "Configuration saved to NVRAM.";
        }
        
        else if (cmd == "disable") {
          _mode = RouterMode.user;
          return "";
        }

      return "% Unknown command";



      /*** GLOBAL CONFIG MODE ***/
      case RouterMode.globalConfig:
        if (cmd == "interface" && args.length >= 2) {
          final iface = args.sublist(1).join("").toLowerCase();

          final ports = router.ports
              .where((p) =>
                  p.name.replaceAll("/", "").toLowerCase() == iface ||
                  p.name.toLowerCase() == iface)
              .toList();

          if (ports.isEmpty) {
            return "% Invalid interface";
          }

          final port = ports.first;
          _activeInterface = port;
          _mode = RouterMode.interfaceConfig;
          return "";
        }
        
        else if (cmd == "ip" && args.length == 5 && args[1] == "route") {
          final dest = args[2];
          final mask = args[3];
          final gateway = args[4];
          router.routingTable.add(RouteEntry(dest, mask, gateway));
          return "";
        }
        
        else if (cmd == "exit") {
          _mode = RouterMode.privileged;
          return "";
        }

      return "% Invalid input";



      /*** INTERFACE CONFIG MODE ***/
      case RouterMode.interfaceConfig:
        if (cmd == "ip" && args.length == 4 &&  args[1].toLowerCase() == "address") {
          _activeInterface?.assignIP(args[2], args[3]);
          return "";
        }
        
        else if (cmd == "no" && args.length >= 2 && args[1].toLowerCase() == "shutdown") {
          _activeInterface?.noShutdown();
          return "";
        }
        
        else if (cmd == "exit") {
          _activeInterface = null;
          _mode = RouterMode.globalConfig;
          return "";
        }

      return "% Invalid interface command";
    }
  }


  String _showIP() {
    return router.ports.map((p) {
      return "${p.name} ${p.ipAddress ?? "unassigned"} "
          "${p.subnetMask ?? ""} "
          "${p.isUp ? "up" : "administratively down"}";
    }).join("\n");
  }


  String _showIPRoutes() {
    if (router.routingTable.isEmpty) { return "No static routes configured."; }
    return router.routingTable.map((r) => "${r.destination} ${r.netmask} via ${r.gateway}").join("\n");
  }


  String _showConnections() {
    return router.ports.map((p) {
      String connection = "unconnected";

      if (p.connectedPC != null) { connection = "PC ${p.connectedPC!.ipAddress}"; }
      else if (p.connectedRouter != null) { connection = "Router ${p.connectedRouter!.name}"; }  
      else if (p.connectedSwitch != null) { connection = "Switch"; }

      return "${p.name}: ${p.ipAddress ?? "no ip"} -> $connection";
    }).join("\n");
  }
}