import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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


  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }


  Future<void> _loadWorkspace() async {
    final items = await loadWorkspace(widget.projectName);
    setState(() {
      droppedItems = items;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [



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
                          await saveWorkspace(widget.projectName, droppedItems);
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
                              child: Text("Workspace Area",style: TextStyle(color: Colors.black54)),
                            ),
                            ...droppedItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              return Positioned(
                                left: item.dx,
                                top: item.dy,

                                child: GestureDetector(
                                  onTap: () async {
                                    if (_selectedToolbar == "Delete") {
                                      setState(() => droppedItems.removeAt(index));
                                    }
                                    
                                    else if (_selectedToolbar == "Inspect Tool" && item.label == "PC") {
                                      final updatedPC = await showDialog<PCDevice>(
                                        context: context,
                                        builder: (ctx) => PCConfigDialog(
                                          pc: item.pcConfig ??
                                              PCDevice(
                                                name: "PC", 
                                                ipAddress: "0.0.0.0",
                                                subnetMask: "255.255.255.0", 
                                                defaultGateway: "0.0.0.0",
                                              ),
                                          onSave: (pc) => Navigator.pop(ctx, pc),
                                        ),
                                      );

                                      if (updatedPC != null) {
                                        setState(() {
                                          droppedItems[index] = droppedItems[index].copyWith(pcConfig: updatedPC);
                                        });
                                      }
                                    }

                                    else if (_selectedToolbar == "Inspect Tool" && item.label.contains("Router")) {
                                      final updatedRouter = await showDialog<RouterDevice>(
                                        context: context,
                                        builder: (ctx) => RouterConfigDialog(
                                          router: item.routerConfig ??
                                            RouterDevice(
                                              name: "Router"
                                            ),
                                          onSave: (router) => Navigator.pop(ctx, router),
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
                                  borderRadius: BorderRadius.circular(8), // 👈 Rounded corners
                                ),
                                padding: const EdgeInsets.all(12),
                                child: _selectedCategory == null
                                    ? const Center(
                                        child: Text("Select a device", style: TextStyle(color: Colors.white54)))
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
  final String label;
  final int iconCodePoint;
  final double dx;
  final double dy;

  final PCDevice? pcConfig;
  final RouterDevice? routerConfig;

  DroppedItem({
    required this.label,
    required this.iconCodePoint,
    required this.dx,
    required this.dy,
    this.pcConfig,
    this.routerConfig,
  });

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
      label: map['label'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      dx: (map['dx'] as num).toDouble(),
      dy: (map['dy'] as num).toDouble(),
      pcConfig: map['pcConfig'] != null ? PCDevice.fromMap(map['pcConfig']) : null,
      routerConfig: map['routerConfig'] != null ? RouterDevice.fromMap(map['routerConfig']) : null,
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





/// --------------------------------
/// SAVING AND LOADING
/// --------------------------------

Future<void> saveWorkspace(String projectName, List<DroppedItem> items) async {
  final ref = FirebaseFirestore.instance.collection('workspaces').doc(projectName);
  await ref.set({
    'items': items.map((e) => e.toMap()).toList(),
  });
}


Future<List<DroppedItem>> loadWorkspace(String projectName) async {
  final ref = FirebaseFirestore.instance.collection('workspaces').doc(projectName);
  final snap = await ref.get();

  if (!snap.exists) return [];

  final data = snap.data() as Map<String, dynamic>;
  final items = (data['items'] as List).map((e) => DroppedItem.fromMap(e)).toList();

  return items;
}

