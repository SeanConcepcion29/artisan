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
  String? _selectedCategory; // 👈 track selected device
  String? _selectedToolbar;
  List<DroppedItem> droppedItems = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

void _showCollaborators(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Collaborators",
          style: TextStyle(color: Colors.white),
        ),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("projects")
              .doc(widget.projectName)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text(
                "No Collaborators.",
                style: TextStyle(color: Colors.white70),
              );
            }

            final rawData = snapshot.data!.data();
            if (rawData == null) {
              return const Text(
                "No project data available.",
                style: TextStyle(color: Colors.white70),
              );
            }

            final data = rawData as Map<String, dynamic>;
            final owner = data["owner"] ?? "Unknown";
            final collabs = List<String>.from(data["collabs"] ?? []);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Owner: $owner",
                    style: const TextStyle(color: Colors.purpleAccent)),
                const SizedBox(height: 12),
                const Text("Collaborators:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                ...collabs.map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(c, style: const TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            );
          },
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          )
        ],
      );
    },
  );
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
            // Top bar
            Container(
              color: const Color.fromARGB(255, 34, 36, 49),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Logo + Project Name
                  Row(
                    children: [
                      SvgPicture.asset('assets/images/logo.svg', height: 30),
                      const SizedBox(width: 8),
                      Text(
                        widget.projectName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  // Right icons
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showCollaborators(context),
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
                      
                      const Icon(Icons.share, color: Colors.white),
                    ],
                  ),

                ],
              ),
            ),

            // Secondary Toolbar
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

            // Workspace
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
                                dy: details.offset.dy - 100, // adjust for top bars if needed
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
                              child: Text("Workspace Area",
                                  style: TextStyle(color: Colors.black54)),
                            ),
                            ...droppedItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              return Positioned(
                                left: item.dx,
                                top: item.dy,
                                child: GestureDetector(
                                  onTap: () {
                                    if (_selectedToolbar == "Delete") {
                                      setState(() => droppedItems.removeAt(index));
                                      // saveWorkspace(widget.projectName, droppedItems); // optional
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
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.replay, color: Colors.white)),
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.play_arrow, color: Colors.white)),
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
                            // LEFT: Device categories
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10), // ✅ added top padding
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Network Devices",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 32,
                                        runSpacing: 16,
                                        children: [
                                          _deviceItem(Icons.router, "Router"),
                                          _deviceItem(Icons.hub, "Hub"),
                                          _deviceItem(Icons.dns, "Switch"),
                                        ],
                                      ),

                                      const SizedBox(height: 20),
                                      const Text("End Devices",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white)),
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
                                      const Text("Connections",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: [
                                          _deviceItem(Icons.cable, "Copper"),
                                          _deviceItem(Icons.settings_input_antenna, "Coaxial"),
                                          _deviceItem(Icons.wifi, "Fiber"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),


                            const SizedBox(width: 20),

                            // RIGHT: Sub-options panel
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
                                        child: Text("Select a device",
                                            style: TextStyle(
                                                color: Colors.white54)))
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedCategory!,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.white)),
                                          const SizedBox(height: 12),

                                          // Example sub-options
                                          if (_selectedCategory == "Switch") ...[
                                            _subOption(Icons.dns, "2960-24TT"),
                                            _subOption(Icons.dns, "2950-24"),
                                          ],
                                          if (_selectedCategory == "Router") ...[
                                            _subOption(Icons.router, "Router 1841"),
                                            _subOption(Icons.router, "Router 2811"),
                                          ],
                                          if (_selectedCategory == "PC") ...[
                                            _subOption(Icons.computer, "Windows PC"),
                                            _subOption(Icons.computer, "Linux PC"),
                                          ],
                                          if (_selectedCategory == "Server") ...[
                                            _subOption(Icons.storage, "Database Server"),
                                            _subOption(Icons.storage, "Web Server"),
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

  // Toolbar button
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
          color: isSelected ? Colors.purple : Colors.white, // ✅ highlight selected
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }


    // Device item
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
            color: isSelected ? Colors.purple : Colors.white, // ✅ purple if selected
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.purple : Colors.white, // ✅ purple if selected
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


  // Sub-option now draggable
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
      color: isDragging ? const Color.fromARGB(160, 55, 55, 55)
                        : const Color.fromARGB(255, 55, 55, 55),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: Colors.white, size: 28),
        const SizedBox(width: 6),
        Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    ),
  );
}


}

/// ----------------
/// Data structures
/// ----------------

class DroppedItem {
  final String label;
  final int iconCodePoint;
  final double dx;
  final double dy;

  DroppedItem({
    required this.label,
    required this.iconCodePoint,
    required this.dx,
    required this.dy,
  });

  /// Convenience getter to build the Icon
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  DroppedItem copyWith({
    String? label,
    int? iconCodePoint,
    double? dx,
    double? dy,
  }) {
    return DroppedItem(
      label: label ?? this.label,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
    );
  }

  /// ✅ Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'iconCodePoint': iconCodePoint,
      'dx': dx,
      'dy': dy,
    };
  }

  /// ✅ Firestore deserialization
  factory DroppedItem.fromMap(Map<String, dynamic> map) {
    return DroppedItem(
      label: map['label'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      dx: (map['dx'] as num).toDouble(),
      dy: (map['dy'] as num).toDouble(),
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

