// project_workspace.dart
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ProjectWorkspacePage extends StatefulWidget {
  final String projectName;

  const ProjectWorkspacePage({super.key, required this.projectName});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  bool _isExpanded = false;
  String? _selectedCategory;
  String? _selectedToolbar = "Select Tool";
  List<DroppedItem> droppedItems = [];

  List<Connection> connections = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    final workspace = await loadWorkspace(widget.projectName);
    setState(() {
      droppedItems = workspace.items;
      connections = workspace.connections;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: const Color.fromARGB(255, 34, 36, 49),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/images/logo.svg', height: 30),
                        const SizedBox(width: 8),
                        Text(
                          widget.projectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => {},
                        child: const Icon(Icons.group, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () async {
                          // Save items + connections
                          await saveWorkspace(
                            widget.projectName,
                            droppedItems,
                            connections,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Workspace saved!")),
                          );
                        },
                        child: const Icon(Icons.save, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => {},
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toolbar row
            Container(
              color: const Color(0xFF2A2B38),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _toolbarButton("Select Tool"),
                  _toolbarButton("Inspect Tool"),
                  _toolbarButton("Delete"),
                  _toolbarButton("Add Note"),
                ],
              ),
            ),

            // Workspace area
            Expanded(
              child: Container(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DragTarget<_DragPayload>(
                      onAcceptWithDetails: (details) {
                        final payload = details.data;

                        setState(() {
                          if (payload.isNew) {
                            droppedItems.add(
                              DroppedItem(
                                label: payload.label!,
                                iconCodePoint: payload.icon!.codePoint,
                                dx: details.offset.dx,
                                dy: details.offset.dy - 100,
                              ),
                            );
                          } else {
                            final index = droppedItems.indexOf(payload.item!);
                            if (index != -1) {
                              droppedItems[index] = droppedItems[index].copyWith(
                                dx: details.offset.dx,
                                dy: details.offset.dy - 100,
                              );
                            }
                          }
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Stack(
                            children: [
                              const Center(
                                child: Text("Workspace Area", style: TextStyle(color: Colors.black54)),
                              ),

                              // 🔥 Connection lines
                              CustomPaint(
                                size: Size.infinite,
                                painter: ConnectionPainter(droppedItems, connections),
                              ),

                              // 🔥 Devices
                              ...droppedItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                              return Positioned(
                                left: item.dx,
                                top: item.dy,
                                child: GestureDetector(
                                  onTap: () async {
                                    // Delete tool: remove item and related connections
                                    if (_selectedToolbar == "Delete") {
                                      final removed = droppedItems.removeAt(index);
                                      // remove any connections tied to removed item
                                      connections.removeWhere((c) =>
                                          c.fromId == removed.id || c.toId == removed.id);
                                      setState(() {});
                                    }

                                    // Inspect Tool - PC
                                    else if (_selectedToolbar == "Inspect Tool" && item.label == "PC") {
                                      final updatedPC = await showDialog<PCDevice>(
                                        context: context,
                                        builder: (ctx) => PCConfigDialog(
                                          pc: item.pcConfig ?? PCDevice(
                                            name: "PC",
                                            ipAddress: "0.0.0.0",
                                            subnetMask: "255.255.255.0",
                                            defaultGateway: "0.0.0.0",
                                          ),
                                          onSave: (pc) => Navigator.pop(ctx, pc),
                                          droppedItems: droppedItems,     // ✅ pass items
                                          connections: connections,       // ✅ pass connections
                                          onConnectionsUpdated: () {      // ✅ tell workspace to refresh
                                            setState(() {});
                                          },
                                        ),
                                      );


                                      if (updatedPC != null) {
                                        setState(() {
                                          droppedItems[index] =
                                              droppedItems[index].copyWith(pcConfig: updatedPC);
                                        });
                                      }
                                    }

                                    // Inspect Tool - Router
                                    else if (_selectedToolbar == "Inspect Tool" &&
                                        item.label.contains("Router")) {
                                          final updatedRouter = await showDialog<RouterDevice>(
                                            context: context,
                                            builder: (ctx) => RouterConfigDialog(
                                              router: item.routerConfig ?? RouterDevice(name: "Router"),
                                              onSave: (router) => Navigator.pop(ctx, router),
                                              droppedItems: droppedItems,
                                              connections: connections,
                                              onConnectionsUpdated: () => setState(() {}), // => forces immediate redraw
                                            ),
                                          );

                                          if (updatedRouter != null) {
                                            setState(() {
                                              droppedItems[index] = droppedItems[index].copyWith(routerConfig: updatedRouter);
                                            });
                                          }

                                    }
                                  },

                                  child: _selectedToolbar == "Select Tool"
                                      ? Draggable<_DragPayload>(
                                          data: _DragPayload.existing(item),
                                          feedback: _workspaceItem(item, isDragging: true),
                                          childWhenDragging: Container(),
                                          child: _workspaceItem(item),
                                        )
                                      : _workspaceItem(item),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Bottom expandable bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              color: const Color(0xFF1E1F2A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: _isExpanded ? 260 : 60,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Expand/Collapse row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2B38),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(onPressed: () {}, icon: const Icon(Icons.replay, color: Colors.white)),
                              IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow, color: Colors.white)),
                            ],
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2B38),
                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            icon: Icon(
                                _isExpanded ? Icons.close : Icons.add,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    if (_isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Network Devices", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 32,
                                        runSpacing: 16,
                                        children: [
                                          _deviceItem(Icons.dns, "Switch"),
                                          _deviceItem(Icons.router, "Router"),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      const Text("End Devices", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 32,
                                        runSpacing: 16,
                                        children: [
                                          _deviceItem(Icons.storage, "Server"),
                                          _deviceItem(Icons.computer, "PC"),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2B38),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: _selectedCategory == null
                                    ? const Center(child: Text("Select a device", style: TextStyle(color: Colors.white54)))
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedCategory!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                          const SizedBox(height: 12),

                                          if (_selectedCategory == "Router") ...[
                                            _subOption(Icons.router, "Router 1841"),
                                            _subOption(Icons.router, "Router 2811"),
                                          ],

                                          if (_selectedCategory == "PC") ...[
                                            _subOption(Icons.computer, "PC"),
                                          ],

                                          if (_selectedCategory == "Server") ...[
                                            _subOption(Icons.storage, "Server"),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(String text) {
    final bool isSelected = _selectedToolbar == text;

    return TextButton(
      onPressed: () {
        setState(() {
          _selectedToolbar = text;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.purple : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _deviceItem(IconData icon, String label) {
    final bool isSelected = _selectedCategory == label;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: isSelected ? Colors.purple : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.purple : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subOption(IconData icon, String name) {
    return Draggable<_DragPayload>(
      data: _DragPayload.newItem(icon, name),
      feedback: _workspaceItem(
        DroppedItem(label: name, iconCodePoint: icon.codePoint, dx: 0, dy: 0),
        isDragging: true,
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(width: 5),
          Text(name, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _workspaceItem(DroppedItem item, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDragging ? const Color.fromARGB(160, 55, 55, 55) : const Color.fromARGB(255, 55, 55, 55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: Colors.white, size: 48),
          const SizedBox(height: 4),
          Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 12)),

          if (item.label == "PC" && item.pcConfig != null) ...[
            const SizedBox(height: 4),
            Text(item.pcConfig!.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          ],

          if (item.label.contains("Router") && item.routerConfig != null) ...[
            const SizedBox(height: 4),
            Text(item.routerConfig!.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

/// --------------------------------
/// DRAGGABLES
/// --------------------------------

class DroppedItem {
  final String id; // unique ID
  final String label;
  final int iconCodePoint;
  final double dx;
  final double dy;

  final PCDevice? pcConfig;
  final RouterDevice? routerConfig;

  DroppedItem({
    String? id,
    required this.label,
    required this.iconCodePoint,
    required this.dx,
    required this.dy,
    this.pcConfig,
    this.routerConfig,
  }) : id = id ?? const Uuid().v4();

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  DroppedItem copyWith({
    String? label,
    int? iconCodePoint,
    double? dx,
    double? dy,
    PCDevice? pcConfig,
    RouterDevice? routerConfig,
  }) {
    return DroppedItem(
      id: id, // preserve existing id
      label: label ?? this.label,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      pcConfig: pcConfig ?? this.pcConfig,
      routerConfig: routerConfig ?? this.routerConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'iconCodePoint': iconCodePoint,
      'dx': dx,
      'dy': dy,
      'pcConfig': pcConfig?.toMap(),
      'routerConfig': routerConfig?.toMap(),
    };
  }

  factory DroppedItem.fromMap(Map<String, dynamic> map) {
    return DroppedItem(
      id: map['id'] as String?,
      label: map['label'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      dx: (map['dx'] as num).toDouble(),
      dy: (map['dy'] as num).toDouble(),
      pcConfig: map['pcConfig'] != null ? PCDevice.fromMap(Map<String, dynamic>.from(map['pcConfig'])) : null,
      routerConfig: map['routerConfig'] != null ? RouterDevice.fromMap(Map<String, dynamic>.from(map['routerConfig'])) : null,
    );
  }
}

class _DragPayload {
  final bool isNew;
  final IconData? icon;
  final String? label;
  final DroppedItem? item;

  _DragPayload.newItem(this.icon, this.label)
      : isNew = true,
        item = null;

  _DragPayload.existing(this.item)
      : isNew = false,
        icon = null,
        label = null;
}

class Connection {
  final String fromId;
  final String toId;

  Connection(this.fromId, this.toId);

  Map<String, dynamic> toMap() => {'from': fromId, 'to': toId};
  factory Connection.fromMap(Map<String, dynamic> map) => Connection(map['from'] as String, map['to'] as String);
}

/// Painter for drawing cable lines between connected items
class ConnectionPainter extends CustomPainter {
  final List<DroppedItem> items;
  final List<Connection> connections;

  ConnectionPainter(this.items, this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    for (var conn in connections) {
      final fromIndex = items.indexWhere((i) => i.id == conn.fromId);
      final toIndex = items.indexWhere((i) => i.id == conn.toId);

      if (fromIndex == -1 || toIndex == -1) continue;

      final from = items[fromIndex];
      final to = items[toIndex];

      final fromOffset = Offset(from.dx + 40, from.dy + 40); // approximate center
      final toOffset = Offset(to.dx + 40, to.dy + 40);

      canvas.drawLine(fromOffset, toOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => true;
}

/// --------------------------------
/// SAVING AND LOADING
/// --------------------------------

class WorkspaceData {
  final List<DroppedItem> items;
  final List<Connection> connections;
  WorkspaceData({required this.items, required this.connections});
}

Future<void> saveWorkspace(String projectName, List<DroppedItem> items, List<Connection> connections) async {
  final ref = FirebaseFirestore.instance.collection('workspaces').doc(projectName);
  await ref.set({
    'items': items.map((e) => e.toMap()).toList(),
    'connections': connections.map((c) => c.toMap()).toList(),
  });
}

Future<WorkspaceData> loadWorkspace(String projectName) async {
  final ref = FirebaseFirestore.instance.collection('workspaces').doc(projectName);
  final snap = await ref.get();

  if (!snap.exists) return WorkspaceData(items: [], connections: []);

  final data = snap.data() as Map<String, dynamic>;
  final rawItems = (data['items'] as List?) ?? [];
  final rawConnections = (data['connections'] as List?) ?? [];

  final items = rawItems
      .map((e) => DroppedItem.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();

  final conns = rawConnections
      .map((e) => Connection.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();

  // 🔥 Restore EthernetPort state from saved connections
  restoreConnections(items, conns);

  return WorkspaceData(items: items, connections: conns);
}

void restoreConnections(List<DroppedItem> droppedItems, List<Connection> connections) {
  for (final conn in connections) {
    final fromItem = safeFind(droppedItems, conn.fromId);
    final toItem = safeFind(droppedItems, conn.toId);

    if (fromItem == null || toItem == null) continue;

    if (fromItem.pcConfig != null && toItem.routerConfig != null) {
      connectPCToRouter(fromItem.pcConfig!, toItem.routerConfig!);
    } else if (fromItem.routerConfig != null && toItem.pcConfig != null) {
      connectPCToRouter(toItem.pcConfig!, fromItem.routerConfig!);
    } else if (fromItem.routerConfig != null && toItem.routerConfig != null) {
      connectRouterToRouter(fromItem.routerConfig!, toItem.routerConfig!);
    }
  }
}

DroppedItem? safeFind(List<DroppedItem> items, String id) {
  try {
    return items.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
}


