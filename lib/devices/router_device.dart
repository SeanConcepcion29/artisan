// router_device.dart
import 'package:flutter/material.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/pages/project_workspace.dart';

class RouterDevice {
  String name;
  bool nameLocked; // <- lock after first change

  // Router has 2 Ethernet ports by default
  final List<EthernetPort> ports = [
    EthernetPort(id: "eth0"),
    EthernetPort(id: "eth1"),
  ];

  RouterDevice({
    required this.name,
    this.nameLocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLocked': nameLocked,
      // ports are ephemeral UI objects; if you want to persist connections you'll persist them separately
    };
  }

  factory RouterDevice.fromMap(Map<String, dynamic> map) {
    return RouterDevice(
      name: map['name'] ?? 'Router',
      nameLocked: map['nameLocked'] == true,
    );
  }

  // Find a free port
  EthernetPort? getFreePort() {
    try {
      return ports.firstWhere((p) => p.isFree);
    } catch (e) {
      return null;
    }
  }
}

/// RouterConfigDialog
class RouterConfigDialog extends StatefulWidget {
  final RouterDevice router;
  final void Function(RouterDevice router) onSave;
  final List<DroppedItem> droppedItems;
  final List<Connection> connections;
  final VoidCallback onConnectionsUpdated; // notify parent to redraw

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

  bool showConfig = false;
  bool showConsole = false;
  bool showConnections = false;

  // allow editing only until the router's name is locked
  late bool isNameEditable;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.router.name);
    isNameEditable = !widget.router.nameLocked;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _menuButton("Console", () => setState(() => showConsole = true)),
              const SizedBox(height: 8),
              _menuButton("Connections", () => setState(() => showConnections = true)),
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

  Widget _menuButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 34, 36, 49),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Config form with one-time name edit (locks after first change)
  Widget _buildConfigForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: 120, child: Text("Router Name:")),
            Expanded(
              child: TextField(
                controller: nameController,
                readOnly: !isNameEditable,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  fillColor: !isNameEditable ? Colors.grey.shade200 : null,
                  filled: !isNameEditable,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // update the existing router instance (not create a new one)
            final newName = nameController.text.trim();
            if (newName.isNotEmpty && widget.router.name != newName) {
              widget.router.name = newName;
            }

            // lock name after first set (if not locked already)
            if (!widget.router.nameLocked && newName.isNotEmpty) {
              widget.router.nameLocked = true;
              isNameEditable = false;
            }

            // notify parent and save
            widget.onSave(widget.router);
            widget.onConnectionsUpdated();

            // (the parent onSave may close the dialog -- typical usage: onSave -> Navigator.pop(ctx, router))
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }

  Widget _buildConsoleUI() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text("Console feature coming soon!", style: TextStyle(fontSize: 14, color: Colors.black54)),
    );
  }

  Widget _buildConnectionsUI() {
    // Get all PCs
    final availablePCs = widget.droppedItems.where((item) => item.pcConfig != null).map((i) => i.pcConfig!).toList();

    // Get all other Routers (exclude self)
    final availableRouters = widget.droppedItems.where((item) => item.routerConfig != null && item.routerConfig != widget.router).map((i) => i.routerConfig!).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Ethernet Ports:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.router.ports.map((port) {
          return ListTile(
            leading: const Icon(Icons.cable, color: Colors.black87),
            title: Text(port.id),
            subtitle: port.isFree ? const Text("Available")
                : Text("Connected to ${port.connectedPC?.name ?? port.connectedRouter?.name ?? 'Unknown'}"),
            trailing: port.isFree
                ? PopupMenuButton<dynamic>(
                    icon: const Icon(Icons.add_link, color: Colors.green),
                    onSelected: (target) {
                      setState(() {
                        if (target is PCDevice) {
                          // connect PC -> this router
                          if (connectPCToRouter(target, widget.router)) {
                            final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == target);
                            final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                            widget.connections.add(Connection(pcItem.id, routerItem.id));
                            widget.onConnectionsUpdated();
                          }
                        } else if (target is RouterDevice) {
                          // router <-> router
                          if (connectRouterToRouter(widget.router, target)) {
                            final r1 = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                            final r2 = widget.droppedItems.firstWhere((i) => i.routerConfig == target);
                            widget.connections.add(Connection(r1.id, r2.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                      });
                    },
                    itemBuilder: (context) {
                      return [
                        ...availablePCs.where((pc) => pc.port.isFree).map((pc) => PopupMenuItem(value: pc, child: Text("PC: ${pc.name}"))),
                        ...availableRouters.where((r) => r.getFreePort() != null).map((r) => PopupMenuItem(value: r, child: Text("Router: ${r.name}"))),
                      ];
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final pc = port.connectedPC;
                        final router = port.connectedRouter;

                        if (pc != null) {
                          // disconnect pc <-> router
                          pc.port.disconnect();
                          port.disconnect();

                          final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == pc);
                          final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);

                          widget.connections.removeWhere((c) =>
                            (c.fromId == pcItem.id && c.toId == routerItem.id) ||
                            (c.fromId == routerItem.id && c.toId == pcItem.id)
                          );
                        } else if (router != null) {
                          // disconnect router <-> router (clear both ports)
                          final otherPort = router.ports.firstWhere((p) => p.connectedRouter == widget.router, orElse: () => router.ports.first);

                          port.disconnect();
                          otherPort.disconnect();

                          final r1 = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                          final r2 = widget.droppedItems.firstWhere((i) => i.routerConfig == router);

                          widget.connections.removeWhere((c) =>
                            (c.fromId == r1.id && c.toId == r2.id) ||
                            (c.fromId == r2.id && c.toId == r1.id)
                          );
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
}

