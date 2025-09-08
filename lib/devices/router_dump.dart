/*
import 'package:flutter/material.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/devices/switch_device.dart';
import 'package:artisan/devices/router_console.dart'; 
import 'package:artisan/pages/project_workspace.dart';

class RouterDevice {
  String name;

  final List<EthernetPort> ports = [
    EthernetPort(id: "fast0/0"),
    EthernetPort(id: "fast0/1")
  ];



  List<String> consoleHistory = [];
  final List<RouteEntry> routingTable = [];


  late RouterConsole console;

  RouterDevice({
    required this.name,
  }) {
    console = RouterConsole(this);
  }

  Map<String, dynamic> runningConfig = {
    "interfaces": <String, Map<String, dynamic>>{},
    "routes": <RouteEntry>[],
  };

  /// Saved config
  Map<String, dynamic> startupConfig = {};

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'consoleHistory': consoleHistory,
    };
  }

  factory RouterDevice.fromMap(Map<String, dynamic> map) {
    final router = RouterDevice(
      name: map['name'] ?? 'Router',
    );
    router.consoleHistory = List<String>.from(map['consoleHistory'] ?? []);
    router.console = RouterConsole(router); 
    return router;
  }

  EthernetPort? getFreePort() {
    try {
      return ports.firstWhere((p) => p.isFree);
    } catch (e) {
      return null;
    }
  }

    /// Apply interface configuration
  void configureInterface(String id, String ip, String mask, {bool noShut = false}) {
    final iface = ports.firstWhere((p) => p.id == id, orElse: () => throw Exception("No such interface"));
    iface.assignIP(ip, mask);
    if (noShut) iface.noShutdown();

    runningConfig["interfaces"][id] = {
      "ip": ip,
      "mask": mask,
      "up": iface.isUp,
    };
  }

  /// Add static route
  void addRoute(String dest, String mask, String gw) {
    final entry = RouteEntry(dest, mask, gw);
    routingTable.add(entry);

    final routes = List<RouteEntry>.from(runningConfig["routes"]);
    routes.add(entry);
    runningConfig["routes"] = routes;
  }

  /// Save config
  void saveConfig() {
    startupConfig = Map.from(runningConfig);
  }
}


class RouteEntry {
  final String destination;
  final String netmask;
  final String gateway;

  RouteEntry(this.destination, this.netmask, this.gateway);

  @override
  String toString() => "$destination $netmask via $gateway";
}


class RouterConfigDialog extends StatefulWidget {
  final RouterDevice router;
  final void Function(RouterDevice router) onSave;

  final List<DroppedItem> droppedItems;
  final List<Connection> connections;
  final VoidCallback onConnectionsUpdated;

  const RouterConfigDialog({
    super.key,
    required this.router,
    required this.onSave,
    required this.droppedItems,
    required this.connections,
    required this.onConnectionsUpdated,
  });

  @override
  State<RouterConfigDialog> createState() => _RouterConfigDialogState();
}

class _RouterConfigDialogState extends State<RouterConfigDialog> {
  late TextEditingController nameController;
  late TextEditingController _consoleController;

  bool showConfig = false;
  bool showConsole = false;
  bool showConnections = false;

  late bool isNameEditable;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.router.name);
    _consoleController = TextEditingController();

    isNameEditable = widget.router.name == "Router";
  }

  @override
  void dispose() {
    nameController.dispose();
    _consoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final hasValidName = widget.router.name != "Router";

    return AlertDialog(
      title: const Text("Router Options", style: TextStyle(fontWeight: FontWeight.bold)),
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
        _field("Router Name:", nameController, readOnly: !isNameEditable),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final updatedRouter = RouterDevice(name: nameController.text);

            if (widget.router.name == "Router" &&
                nameController.text != "Router") {
              setState(() {
                isNameEditable = false;
              });
            }

            widget.onSave(updatedRouter);
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
            children: widget.router.consoleHistory.map((line) {
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
          widget.router.console.getPrompt(),
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
        .where((item) => item.routerConfig != null && item.routerConfig != widget.router)
        .map((i) => i.routerConfig!)
        .toList();

    final availableSwitches = widget.droppedItems
        .where((item) => item.switchConfig != null)
        .map((i) => i.switchConfig!)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Ethernet Ports:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.router.ports.map((port) {
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
                          if (connectPCToRouter(target, widget.router)) {
                            final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == target);
                            final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                            widget.connections.add(Connection(pcItem.id, routerItem.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                        
                        else if (target is RouterDevice) {
                          if (connectRouterToRouter(widget.router, target)) {
                            final r1 = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                            final r2 = widget.droppedItems.firstWhere((i) => i.routerConfig == target);
                            widget.connections.add(Connection(r1.id, r2.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                        
                        else if (target is SwitchDevice) {
                          if (connectRouterToSwitch(widget.router, target)) {
                            final rItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                            final swItem = widget.droppedItems.firstWhere((i) => i.switchConfig == target);
                            widget.connections.add(Connection(rItem.id, swItem.id));
                            widget.onConnectionsUpdated();
                          }
                        }

                      });
                    },
                    itemBuilder: (context) {
                      return [
                        ...availablePCs.where((pc) => pc.port.isFree).map((pc) => PopupMenuItem(value: pc, child: Text("[PC] ${pc.name}"))),
                        ...availableRouters.where((r) => r.getFreePort() != null).map((r) => PopupMenuItem(value: r, child: Text("[ROUTER] ${r.name}"))),
                        ...availableSwitches.where((s) => s.getFreePort() != null).map((s) => PopupMenuItem(value: s, child: Text("[SWITCH] ${s.name}"))),
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

                          final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == pc);
                          final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                          widget.connections.removeWhere((c) =>
                              (c.fromId == pcItem.id && c.toId == routerItem.id) ||
                              (c.fromId == routerItem.id && c.toId == pcItem.id));
                        }
                        
                        else if (router != null) {
                          final otherPort = router.ports.firstWhere(
                            (p) => p.connectedRouter == widget.router,
                            orElse: () => router.ports.first,
                          );

                          port.disconnect();
                          otherPort.disconnect();

                          final r1 = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                          final r2 = widget.droppedItems.firstWhere((i) => i.routerConfig == router);

                          widget.connections.removeWhere((c) =>
                              (c.fromId == r1.id && c.toId == r2.id) ||
                              (c.fromId == r2.id && c.toId == r1.id));
                        }
                        
                        else if (sw != null) {
                          final otherPort = sw.ports.firstWhere(
                            (p) => p.connectedRouter == widget.router,
                            orElse: () => sw.ports.first,
                          );

                          port.disconnect();
                          otherPort.disconnect();

                          final rItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                          final swItem = widget.droppedItems.firstWhere((i) => i.switchConfig == sw);

                          widget.connections.removeWhere((c) =>
                              (c.fromId == rItem.id && c.toId == swItem.id) ||
                              (c.fromId == swItem.id && c.toId == rItem.id));
                        }

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
      widget.router.consoleHistory.add("${widget.router.console.getPrompt()} $cmd");
      final output = widget.router.console.processCommand(cmd);
      if (output.isNotEmpty) { widget.router.consoleHistory.add(output); }
      _consoleController.clear();
    });
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


extension RouterPing on RouterDevice {
  String handlePing(PCDevice source, String targetIP) {
    // Check directly connected PCs
    for (var p in ports) {
      if (p.connectedPC != null && p.connectedPC!.ipAddress == targetIP) {
        return "Reply from $targetIP: bytes=32 time<1ms TTL=64";
      }
    }

    // Check directly connected router
    for (var p in ports) {
      if (p.connectedRouter != null) {
        final result = p.connectedRouter!.handlePing(source, targetIP);
        if (!result.contains("unreachable")) return result;
      }
    }

    // TODO: check static routes if you have them
    return "Destination host unreachable.";
  }
}
*/