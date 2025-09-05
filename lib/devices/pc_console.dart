import 'package:artisan/devices/pc_device.dart';

class PCConsole {
  final PCDevice pc;

  PCConsole(this.pc);

  String getPrompt() => "[user@localhost ~]\$";

  String processCommand(String input) {
    input = input.trim();
    if (input.isEmpty) return "";

    switch (input.toLowerCase()) {
      case "ipconfig":
        return "IP Address: ${pc.ipAddress}\nSubnet Mask: ${pc.subnetMask}\nDefault Gateway: ${pc.defaultGateway}";
      case "help":
        return "Available commands:\n- ipconfig\n- help\n- clear";
      case "clear":
        pc.consoleHistory.clear();
        return "";
      default:
        return "Unknown command: $input";
    }
  }
}
