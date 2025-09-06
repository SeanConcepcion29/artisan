import 'package:artisan/devices/switch_console.dart';
import 'package:flutter/material.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/pages/project_workspace.dart';

class SwitchDevice {
  String name;

  final List<EthernetPort> ports = [
    EthernetPort(id: "eth0/0"),
    EthernetPort(id: "eth0/1"),
    EthernetPort(id: "eth0/2"),
    EthernetPort(id: "eth0/3"),
    EthernetPort(id: "fast0/0"),
    EthernetPort(id: "fast0/1"),
  ];


  List<String> consoleHistory = [];
  late SwitchConsole console;

  SwitchDevice({
    required this.name
  }) {
    console = SwitchConsole(this);
  }


  EthernetPort? getFreePort() {
    try {
      return ports.firstWhere((p) => p.isFree);
    } catch (e) {
      return null;
    }
  }

  EthernetPort? getPortById(String id) {
    try {
      return ports.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'consoleHistory': consoleHistory,
    };
  }

  factory SwitchDevice.fromMap(Map<String, dynamic> map) {
    final sw = SwitchDevice(
      name: map['name'] ?? 'Switch',
    );
    sw.consoleHistory = List<String>.from(map['consoleHistory'] ?? []);
    return sw;
  }

}

class SwitchConfigDialog extends StatefulWidget {
  final SwitchDevice sw;
  final void Function(SwitchDevice sw) onSave;

  /* MANAGE WORKSPACE CONNECTIONS */
  final List<DroppedItem> droppedItems;
  final List<Connection> connections;
  final VoidCallback onConnectionsUpdated;

  const SwitchConfigDialog({
    super.key,
    required this.sw,
    required this.onSave,
    required this.droppedItems,
    required this.connections,
    required this.onConnectionsUpdated,
  });

  @override
  State<SwitchConfigDialog> createState() => _SwitchConfigDialogState();
}

class _SwitchConfigDialogState extends State<SwitchConfigDialog> {
  late TextEditingController nameController;
  late TextEditingController _consoleController;

  bool showConfig = false;
  bool showConsole = false;
  bool showConnections = false;

  late bool isNameEditable;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.sw.name);
    _consoleController = TextEditingController();

    isNameEditable = widget.sw.name == "Switch";
  }

  @override
  void dispose() {
    nameController.dispose();
    _consoleController.dispose();
    super.dispose();
  }

  bool get hasValidName => widget.sw.name != "Switch";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Switch Options", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showConfig && !showConsole && !showConnections) ...[
              _menuButton("Configure", () => setState(() => showConfig = true)),
              const SizedBox(height: 8),
              _menuButton("Console", () => setState(() => showConsole = true), enabled: hasValidName),
              const SizedBox(height: 8),
              _menuButton("Connections", () => setState(() => showConnections = true), enabled: hasValidName),
            ],
            if (showConfig) _buildConfigForm(),
            if (showConsole) _buildConsoleUI(),
            if (showConnections) _buildConnectionsUI(),
          ],
        ),
      ),
      actions: [
        if (showConfig || showConsole || showConnections)
          TextButton(
            onPressed: () => setState(() {
              showConfig = false;
              showConsole = false;
              showConnections = false;
            }),
            child: const Text("Back", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _menuButton(String text, VoidCallback? onPressed,
      {bool enabled = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? const Color.fromARGB(255, 34, 36, 49) : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildConfigForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field("Switch Name:", nameController, readOnly: !isNameEditable),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.sw.name = nameController.text;
              if (widget.sw.name != "Switch") {
                isNameEditable = false;
              }
            });
            widget.onSave(widget.sw); 
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }

Widget _buildConsoleUI() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListView(
          children: widget.sw.consoleHistory.map((line) {
            return Text(
              line,
              style: const TextStyle(
                color: Colors.green,
                fontFamily: "monospace",
                fontSize: 10,
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),

      Text(
        "${widget.sw.name}>", 
        style: const TextStyle(
          color: Colors.green,
          fontFamily: "monospace",
          fontSize: 12,
          fontWeight: FontWeight.bold
        ),
      ),
      const SizedBox(height: 4),

      TextField(
        controller: _consoleController,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: "monospace",
          fontSize: 10,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            onPressed: () => _handleCommand(_consoleController.text),
          ),
          hintText: "Enter command...",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        onSubmitted: (cmd) => _handleCommand(cmd),
      ),
    ],
  );
}



  Widget _buildConnectionsUI() {
    final availablePCs = widget.droppedItems
        .where((item) => item.pcConfig != null)
        .map((i) => i.pcConfig!)
        .toList();

    final availableRouters = widget.droppedItems
        .where((item) => item.routerConfig != null)
        .map((i) => i.routerConfig!)
        .toList();

    final availableSwitches = widget.droppedItems
        .where((item) => item.switchConfig != null && item.switchConfig != widget.sw)
        .map((i) => i.switchConfig!)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Ethernet Ports:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.sw.ports.map((port) {
          return ListTile(
            leading: const Icon(Icons.cable, color: Colors.black87),
            title: Text(port.id),
            subtitle: port.isFree
                ? const Text("Available")
                : Text("Connected to ${port.connectedPC?.name ?? port.connectedRouter?.name ?? port.connectedSwitch?.name ?? 'Unknown'}"),
            trailing: port.isFree
                ? PopupMenuButton<dynamic>(
                    icon: const Icon(Icons.add_link, color: Colors.green),
                    onSelected: (target) {
                      setState(() {
                        if (target is PCDevice) {
                          if (connectPCToSwitch(target, widget.sw)) {
                            final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == target);
                            final swItem = widget.droppedItems.firstWhere((i) => i.switchConfig == widget.sw);
                            widget.connections.add(Connection(pcItem.id, swItem.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                        
                        else if (target is RouterDevice) {
                          if (connectRouterToSwitch(target, widget.sw)) {
                            final rItem = widget.droppedItems.firstWhere((i) => i.routerConfig == target);
                            final swItem = widget.droppedItems.firstWhere((i) => i.switchConfig == widget.sw);
                            widget.connections.add(Connection(rItem.id, swItem.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                        
                        else if (target is SwitchDevice) {
                          if (connectSwitchToSwitch(widget.sw, target)) {
                            final s1 = widget.droppedItems.firstWhere((i) => i.switchConfig == widget.sw);
                            final s2 = widget.droppedItems.firstWhere((i) => i.switchConfig == target);
                            widget.connections.add(Connection(s1.id, s2.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                      });
                    },
                    itemBuilder: (context) {
                      return [
                        ...availablePCs
                            .where((pc) => pc.port.isFree)
                            .map((pc) => PopupMenuItem(value: pc, child: Text("[PC] ${pc.name}"))),
                        ...availableRouters
                            .where((r) => r.getFreePort() != null)
                            .map((r) => PopupMenuItem(value: r, child: Text("[ROUTER] ${r.name}"))),
                        ...availableSwitches
                            .where((s) => s.getFreePort() != null)
                            .map((s) => PopupMenuItem(value: s, child: Text("[SWITCH] ${s.name}"))),
                      ];
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final pc = port.connectedPC;
                        final router = port.connectedRouter;
                        final sw = port.connectedSwitch;

                        if (pc != null) {
                          pc.port.disconnect();
                          port.disconnect();
                        }
                        
                        else if (router != null) {
                          final otherPort = router.ports.firstWhere(
                            (p) => p.connectedSwitch == widget.sw,
                            orElse: () => router.ports.first,
                          );
                          port.disconnect();
                          otherPort.disconnect();
                        }
                        
                        else if (sw != null) {
                          final otherPort = sw.ports.firstWhere(
                            (p) => p.connectedSwitch == widget.sw,
                            orElse: () => sw.ports.first,
                          );
                          port.disconnect();
                          otherPort.disconnect();
                        }

                        widget.connections.removeWhere((c) => c.fromId == port.id || c.toId == port.id);
                        widget.onConnectionsUpdated();
                      });
                    },
                  ),
          );
        }),
      ],
    );
  }

  
  void _handleCommand(String cmd) {
    cmd = cmd.trim();
    if (cmd.isEmpty) return;

    setState(() {
      widget.sw.consoleHistory.add("${widget.sw.console.getPrompt()} $cmd");
      final output = widget.sw.console.processCommand(cmd);
      if (output.isNotEmpty) widget.sw.consoleHistory.add(output);
      _consoleController.clear();
    });
  }


  Widget _field(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              fillColor: readOnly ? Colors.grey.shade200 : null,
              filled: readOnly,
            ),
          ),
        ),
      ],
    );
  }
}

extension SwitchPing on SwitchDevice {
  String handlePing(PCDevice source, String targetIP) {
    for (var p in ports) {
      if (p.connectedPC != null && p.connectedPC!.ipAddress == targetIP) {
        return "Reply from $targetIP: bytes=32 time<1ms TTL=64";
      }
      if (p.connectedRouter != null) {
        final result = p.connectedRouter!.handlePing(source, targetIP);
        if (!result.contains("unreachable")) return result;
      }
      if (p.connectedSwitch != null && p.connectedSwitch != this) {
        final result = p.connectedSwitch!.handlePing(source, targetIP);
        if (!result.contains("unreachable")) return result;
      }
    }
    return "Destination host unreachable.";
  }
}
