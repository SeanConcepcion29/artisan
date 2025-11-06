import 'package:artisan/devices/switch_device.dart';


class SwitchConsole {
  final SwitchDevice sw;

  SwitchConsole(this.sw);

  /* sets the prompt for switch CLI */
  String getPrompt() => "${sw.name}>";

  /* FUNCTION that reads and processes cli input to determine command to execute */
  String processCommand(String input) {
    if (input.trim().isEmpty) return "";

    final args = input.trim().split(RegExp(r"\s+"));
    final cmd = args.first.toLowerCase();


    if (cmd == "show" && args.length >= 2 && args[1] == "mac") {
      return "MAC Table (connected devices):\n${sw.ports
          .map((p) =>
              "${p.id}: ${p.connectedPC?.name ?? p.connectedRouter?.name ?? p.connectedSwitch?.name ?? '---'}")
          .join("\n")}";
    }


    else if (cmd == "show" && args.length >= 2 && args[1] == "vlan") {
      final vlanMap = <int, List<String>>{};
      for (final port in sw.ports) {
        vlanMap.putIfAbsent(port.vlanId, () => []).add(port.name);
      }

      if (vlanMap.isEmpty) return "No VLANs configured.";
      return vlanMap.entries
          .map((e) => "VLAN ${e.key}: ${e.value.join(', ')}")
          .join("\n");
    }


    else if (cmd == "set" && args.length >= 4 && args[1].toLowerCase() == "vlan") {
      final portName = args[2];
      final vlanId = int.tryParse(args[3]);
      if (vlanId == null) return "Invalid VLAN ID";

      final port = sw.ports.firstWhere(
        (p) => p.name == portName,
        orElse: () => throw Exception("Port not found"),
      );

      port.vlanId = vlanId;
      return "Port $portName assigned to VLAN $vlanId";
    }


    else if (cmd == "clear") {
      sw.consoleHistory.clear();
      return "";
    }


    else if (cmd == "help") {
      return """
  Available commands:
    show mac        - Show MAC table
    show vlan       - Show VLAN assignments
    set vlan <port> <id> - Assign VLAN to port
    clear           - Clear console
    help            - Show this help
  """.trim();
    }


    else {
      return "Unknown command: $input";
    }
  }

}
