import 'package:artisan/devices/router_device.dart';
import 'package:flutter/material.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/pages/project_workspace.dart';

class PCDevice {
  String name;
  String ipAddress;
  String subnetMask;
  String defaultGateway;

  final EthernetPort port = EthernetPort(id: "eth0");

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
    };
  }

  factory PCDevice.fromMap(Map<String, dynamic> map) {
    return PCDevice(
      name: map['name'] ?? 'PC',
      ipAddress: map['ipAddress'] ?? '0.0.0.0',
      subnetMask: map['subnetMask'] ?? '255.255.255.0',
      defaultGateway: map['defaultGateway'] ?? '0.0.0.0',
    );
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

  bool showConfig = false;
  bool showPing = false;
  bool showConnections = false;

  late bool isNameEditable;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.pc.name);
    ipController = TextEditingController(text: widget.pc.ipAddress);
    maskController = TextEditingController(text: widget.pc.subnetMask.isNotEmpty ? widget.pc.subnetMask : "255.255.255.0");
    gatewayController = TextEditingController(text: widget.pc.defaultGateway);

    isNameEditable = widget.pc.name == "PC";
  }

  @override
  void dispose() {
    nameController.dispose();
    ipController.dispose();
    maskController.dispose();
    gatewayController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("PC Options", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showConfig && !showPing && !showConnections) ...[
              _menuButton("Configure", () => setState(() => showConfig = true)),
              const SizedBox(height: 8),
              _menuButton("Ping", () => setState(() => showPing = true)),
              const SizedBox(height: 8),
              _menuButton("Connections", () => setState(() => showConnections = true)),
            ],
            if (showConfig) _buildConfigForm(),
            if (showPing) _buildPingUI(),
            if (showConnections) _buildConnectionsUI(),
          ],
        ),
      ),

      actions: [
        if (showConfig || showPing || showConnections)
          TextButton(
            onPressed: () => setState(() { showConfig = false; showPing = false; showConnections = false; }),
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
        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 34, 36, 49), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
            final updatedPC = PCDevice(
              name: nameController.text,
              ipAddress: ipController.text,
              subnetMask: maskController.text,
              defaultGateway: gatewayController.text,
            );

            if (widget.pc.name == "PC" && nameController.text != "PC") {
              setState(() { isNameEditable = false; });
            }

            widget.onSave(updatedPC);
          },

          child: const Text("Apply"),
        ),
      ],
    );
  }


  Widget _buildPingUI() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text("Ping feature coming soon!", style: TextStyle(fontSize: 14, color: Colors.black54)),
    );
  }


  Widget _buildConnectionsUI() {

    /*** GET ALL ROUTERS FROM droppedItems ***/
    final availableRouters = widget.droppedItems
        .where((item) => item.routerConfig != null)
        .map((item) => item.routerConfig!)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Ethernet Port:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        ListTile(
          leading: const Icon(Icons.cable, color: Colors.black87),
          title: Text(widget.pc.port.id),
          subtitle: widget.pc.port.isFree ? const Text("Not connected") : Text("Connected to ${widget.pc.port.connectedRouter?.name ?? 'Router'}"),
          trailing: widget.pc.port.isFree

              /*** NO CONNECTION ***/
              ? PopupMenuButton<RouterDevice>(
                  icon: const Icon(Icons.add_link, color: Colors.green),
                  onSelected: (router) {
                    setState(() {
                      if (connectPCToRouter(widget.pc, router)) {
                        final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == widget.pc);
                        final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == router);
                        widget.connections.add(Connection(pcItem.id, routerItem.id));
                        widget.onConnectionsUpdated(); 
                      }
                    });
                  },
                  itemBuilder: (context) {
                    return availableRouters
                        .where((router) => router.getFreePort() != null)
                        .map((router) => PopupMenuItem(value: router, child: Text("[ROUTER] ${router.name}")))
                        .toList();
                  },
                )

              /*** CONNECTED ALREADY ***/
              : IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      final router = widget.pc.port.connectedRouter;
                      if (router != null) {
                        final routerPort = router.ports.firstWhere(
                          (p) => p.connectedPC == widget.pc,
                          orElse: () => router.ports.first,
                        );

                        widget.pc.port.disconnect();
                        routerPort.disconnect();

                        final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == widget.pc);
                        final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == router);

                        /*** REMOVE CONNECTION ***/
                        widget.connections.removeWhere(
                          (c) =>
                              (c.fromId == pcItem.id &&
                                  c.toId == routerItem.id) ||
                              (c.fromId == routerItem.id &&
                                  c.toId == pcItem.id),
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