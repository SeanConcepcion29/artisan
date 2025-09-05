import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/switch_device.dart';
import 'package:flutter/material.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/pages/project_workspace.dart';

class PCDevice {
  String name;
  String ipAddress;
  String subnetMask;
  String defaultGateway;

  final EthernetPort port = EthernetPort(id: "eth0");

  // Console state
  List<String> consoleHistory = [];

  PCDevice({
    required this.name,
    required this.ipAddress,
    this.subnetMask = "255.255.255.0",
    required this.defaultGateway,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ipAddress': ipAddress,
      'subnetMask': subnetMask,
      'defaultGateway': defaultGateway,
      'consoleHistory': consoleHistory,
    };
  }

  factory PCDevice.fromMap(Map<String, dynamic> map) {
    return PCDevice(
      name: map['name'] ?? 'PC',
      ipAddress: map['ipAddress'] ?? '0.0.0.0',
      subnetMask: map['subnetMask'] ?? '255.255.255.0',
      defaultGateway: map['defaultGateway'] ?? '0.0.0.0',
    )..consoleHistory = List<String>.from(map['consoleHistory'] ?? []);
  }

  /// Process commands for the PC console
  String processCommand(String input) {
    if (input.trim().isEmpty) return "";
    switch (input.toLowerCase()) {
      case "ipconfig":
        return "IP Address: $ipAddress\nSubnet Mask: $subnetMask\nDefault Gateway: $defaultGateway";
      case "help":
        return "Available commands:\n- ipconfig\n- help\n- clear";
      case "clear":
        consoleHistory.clear();
        return "";
      default:
        return "Unknown command: $input";
    }
  }
}

class PCConfigDialog extends StatefulWidget {
  final PCDevice pc;
  final void Function(PCDevice pc) onSave;

  /* MANAGE WORKSPACE CONNECTIONS */
  final List<DroppedItem> droppedItems;
  final List<Connection> connections;
  final VoidCallback onConnectionsUpdated;

  const PCConfigDialog({
    super.key,
    required this.pc,
    required this.onSave,
    required this.droppedItems,
    required this.connections,
    required this.onConnectionsUpdated,
  });

  @override
  State<PCConfigDialog> createState() => _PCConfigDialogState();
}

class _PCConfigDialogState extends State<PCConfigDialog> {
  late TextEditingController nameController;
  late TextEditingController ipController;
  late TextEditingController maskController;
  late TextEditingController gatewayController;

  late TextEditingController _consoleController;

  bool showConfig = false;
  bool showPing = false;
  bool showConnections = false;
  bool showConsole = false;

  late bool isNameEditable;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.pc.name);
    ipController = TextEditingController(text: widget.pc.ipAddress);
    maskController = TextEditingController(
      text: widget.pc.subnetMask.isNotEmpty ? widget.pc.subnetMask : "255.255.255.0",
    );
    gatewayController = TextEditingController(text: widget.pc.defaultGateway);

    _consoleController = TextEditingController();

    isNameEditable = widget.pc.name == "PC";
  }

  @override
  void dispose() {
    nameController.dispose();
    ipController.dispose();
    maskController.dispose();
    gatewayController.dispose();
    _consoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValidName = widget.pc.name != "PC";

    return AlertDialog(
      title: const Text("PC Options", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showConfig && !showPing && !showConnections && !showConsole) ...[
              _menuButton("Configure", () => setState(() => showConfig = true)),
              const SizedBox(height: 8),
              _menuButton("Ping", () => setState(() => showPing = true), enabled: hasValidName),
              const SizedBox(height: 8),
              _menuButton("Connections", () => setState(() => showConnections = true), enabled: hasValidName),
              const SizedBox(height: 8),
              _menuButton("Console", () => setState(() => showConsole = true), enabled: hasValidName),
            ],
            if (showConfig) _buildConfigForm(),
            if (showPing) _buildPingUI(),
            if (showConnections) _buildConnectionsUI(),
            if (showConsole) _buildConsoleUI(),
          ],
        ),
      ),
      actions: [
        if (showConfig || showPing || showConnections || showConsole)
          TextButton(
            onPressed: () => setState(() {
              showConfig = false;
              showPing = false;
              showConnections = false;
              showConsole = false;
            }),
            child: const Text("Back",
                style: TextStyle(
                    color: Color.fromARGB(255, 34, 36, 49),
                    fontWeight: FontWeight.bold)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close",
              style: TextStyle(
                  color: Color.fromARGB(255, 34, 36, 49),
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _menuButton(String text, VoidCallback onPressed, {bool enabled = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? const Color.fromARGB(255, 34, 36, 49)
              : Colors.grey,
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
        _field("PC Name:", nameController, readOnly: !isNameEditable),
        const SizedBox(height: 8),
        _field("IP Address:", ipController),
        const SizedBox(height: 8),
        _field("Subnet Mask:", maskController),
        const SizedBox(height: 8),
        _field("Default Gateway:", gatewayController),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            widget.pc.name = nameController.text;
            widget.pc.ipAddress = ipController.text;
            widget.pc.subnetMask = maskController.text;
            widget.pc.defaultGateway = gatewayController.text;

            if (widget.pc.name == "PC" && nameController.text != "PC") {
              setState(() {
                isNameEditable = false;
              });
            }

            widget.onSave(widget.pc);
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }

  Widget _buildPingUI() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text("Ping feature coming soon!",
          style: TextStyle(fontSize: 14, color: Colors.black54)),
    );
  }

  Widget _buildConnectionsUI() {
    final availableRouters = widget.droppedItems
        .where((item) => item.routerConfig != null)
        .map((item) => item.routerConfig!)
        .toList();

    final availableSwitches = widget.droppedItems
        .where((item) => item.switchConfig != null)
        .map((item) => item.switchConfig!)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Ethernet Port:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.cable, color: Colors.black87),
          title: Text(widget.pc.port.id),
          subtitle: widget.pc.port.isFree
              ? const Text("Not connected")
              : Text("Connected to ${widget.pc.port.connectedRouter?.name ?? widget.pc.port.connectedSwitch?.name ?? 'Unknown'}"),
          trailing: widget.pc.port.isFree
              ? PopupMenuButton<dynamic>(
                  icon: const Icon(Icons.add_link, color: Colors.green),
                  onSelected: (target) {
                    setState(() {
                      if (target is RouterDevice) {
                        if (connectPCToRouter(widget.pc, target)) {
                          final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == widget.pc);
                          final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == target);
                          widget.connections.add(Connection(pcItem.id, routerItem.id));
                          widget.onConnectionsUpdated();
                        }
                      } else if (target is SwitchDevice) {
                        if (connectPCToSwitch(widget.pc, target)) {
                          final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == widget.pc);
                          final swItem = widget.droppedItems.firstWhere((i) => i.switchConfig == target);
                          widget.connections.add(Connection(pcItem.id, swItem.id));
                          widget.onConnectionsUpdated();
                        }
                      }
                    });
                  },
                  itemBuilder: (context) {
                    return [
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
                      final router = widget.pc.port.connectedRouter;
                      final sw = widget.pc.port.connectedSwitch;

                      if (router != null) {
                        final routerPort = router.ports.firstWhere(
                          (p) => p.connectedPC == widget.pc,
                          orElse: () => router.ports.first,
                        );
                        widget.pc.port.disconnect();
                        routerPort.disconnect();

                        final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == widget.pc);
                        final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == router);
                        widget.connections.removeWhere(
                          (c) =>
                              (c.fromId == pcItem.id && c.toId == routerItem.id) ||
                              (c.fromId == routerItem.id && c.toId == pcItem.id),
                        );
                        widget.onConnectionsUpdated();
                      } else if (sw != null) {
                        final swPort = sw.ports.firstWhere(
                          (p) => p.connectedPC == widget.pc,
                          orElse: () => sw.ports.first,
                        );
                        widget.pc.port.disconnect();
                        swPort.disconnect();

                        final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == widget.pc);
                        final swItem = widget.droppedItems.firstWhere((i) => i.switchConfig == sw);
                        widget.connections.removeWhere(
                          (c) =>
                              (c.fromId == pcItem.id && c.toId == swItem.id) ||
                              (c.fromId == swItem.id && c.toId == pcItem.id),
                        );
                        widget.onConnectionsUpdated();
                      }
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConsoleUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView(
            children: widget.pc.consoleHistory.map((line) {
              return Text(
                line,
                style: const TextStyle(color: Colors.green, fontFamily: "monospace"),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _consoleController,
          style: const TextStyle(color: Colors.white, fontFamily: "monospace"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            border: const OutlineInputBorder(),
            hintText: "Enter command...",
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                final cmd = _consoleController.text.trim();
                if (cmd.isEmpty) return;

                setState(() {
                  widget.pc.consoleHistory.add("> $cmd");
                  final output = widget.pc.processCommand(cmd);
                  if (output.isNotEmpty) {
                    widget.pc.consoleHistory.add(output);
                  }
                  _consoleController.clear();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {bool readOnly = false}) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              fillColor: readOnly ? Colors.grey.shade200 : null,
              filled: readOnly,
            ),
          ),
        ),
      ],
    );
  }
}
