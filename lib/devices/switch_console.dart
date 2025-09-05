import 'package:artisan/devices/switch_device.dart';

class SwitchConsole {
  final SwitchDevice sw;

  SwitchConsole(this.sw);

  String getPrompt() => "${sw.name}>";

  String processCommand(String input) {
    if (input.trim().isEmpty) return "";
    switch (input.toLowerCase()) {
      case "show mac":

        return "MAC Table (connected devices):\n${sw.ports
                .map((p) => "${p.id}: ${p.connectedPC?.name ?? p.connectedRouter?.name ?? p.connectedSwitch?.name ?? '---'}")
                .join("\n")}";
      case "help":
        return "Available commands:\n- show mac\n- help\n- clear";
      case "clear":
        sw.consoleHistory.clear();
        return "";
      default:
        return "Unknown command: $input";
    }
  }
}
