// router_device.dart
import 'package:flutter/material.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/pages/project_workspace.dart';

class RouterDevice {
  String name;

  final List<EthernetPort> ports = [EthernetPort(id: "eth0"), EthernetPort(id: "eth1")];

  RouterDevice({
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory RouterDevice.fromMap(Map<String, dynamic> map) {
    return RouterDevice(
      name: map['name'] ?? 'Router',
    );
  }

  EthernetPort? getFreePort() {
    try {
      return ports.firstWhere((p) => p.isFree);
    } catch (e) {
      return null;
    }
  }
}



class RouterConfigDialog extends StatefulWidget {
  final RouterDevice router;
  final void Function(RouterDevice router) onSave;

  /* MANAGE WORKSPACE CONNECTIONS */
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

  bool showConfig = false;
  bool showConsole = false;
  bool showConnections = false;


  late bool isNameEditable;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.router.name);

    isNameEditable = widget.router.name == "Router";
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
            onPressed: () => setState(() { showConfig = false; showConsole = false; showConnections = false; }),
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
        _field("Router Name:", nameController, readOnly: !isNameEditable),
        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: () {
            final updatedRouter = RouterDevice(
              name: nameController.text,
            );

            if (widget.router.name == "Router" && nameController.text != "Router") {
              setState(() { isNameEditable = false; });
            }

            widget.onSave(updatedRouter);
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

    /*** GET ALL PCs FROM droppedItems ***/
    final availablePCs = widget.droppedItems
      .where((item) => item.pcConfig != null)
      .map((i) => i.pcConfig!)
      .toList();

    /*** GET ALL ROUTERS FROM droppedItems EXCEPT SELF ***/
    final availableRouters = widget.droppedItems
      .where((item) => item.routerConfig != null && item.routerConfig != widget.router)
      .map((i) => i.routerConfig!)
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
            subtitle: port.isFree ? const Text("Available") : Text("Connected to ${port.connectedPC?.name ?? port.connectedRouter?.name ?? 'Unknown'}"),
            trailing: port.isFree

                /*** NO CONNECTION ***/
                ? PopupMenuButton<dynamic>(
                    icon: const Icon(Icons.add_link, color: Colors.green),
                    onSelected: (target) {
                      setState(() {

                        /*** CONNECT PC TO THIS ROUTER ***/
                        if (target is PCDevice) {
                          if (connectPCToRouter(target, widget.router)) {
                            final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == target);
                            final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);
                            widget.connections.add(Connection(pcItem.id, routerItem.id));
                            widget.onConnectionsUpdated();
                          }
                        }
                        
                        /*** CONNECT ROUTER TO THIS ROUTER ***/
                        else if (target is RouterDevice) {                  
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
                        ...availablePCs.where((pc) => pc.port.isFree).map((pc) => PopupMenuItem(value: pc, child: Text("[PC] ${pc.name}"))),
                        ...availableRouters.where((r) => r.getFreePort() != null).map((r) => PopupMenuItem(value: r, child: Text("[ROUTER] ${r.name}"))),
                      ];
                    },
                  )

                /*** CONNECTED ALREADY ***/
                : IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final pc = port.connectedPC;
                        final router = port.connectedRouter;

                        /*** REMOVE PC CONNECTION ***/
                        if (pc != null) {
                          pc.port.disconnect();
                          port.disconnect();

                          final pcItem = widget.droppedItems.firstWhere((i) => i.pcConfig == pc);
                          final routerItem = widget.droppedItems.firstWhere((i) => i.routerConfig == widget.router);

                          widget.connections.removeWhere((c) =>
                            (c.fromId == pcItem.id && c.toId == routerItem.id) ||
                            (c.fromId == routerItem.id && c.toId == pcItem.id)
                          );
                        }
                        
                        /*** REMOVE ROUTER CONNECTION ***/
                        else if (router != null) {
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