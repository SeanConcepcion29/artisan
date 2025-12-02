import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:artisan/services/firestore_project.dart';
import 'package:artisan/services/firestore_notif.dart';
import 'package:artisan/devices/ethernet_port.dart';
import 'package:artisan/devices/pc_device.dart';
import 'package:artisan/devices/router_device.dart';
import 'package:artisan/devices/switch_device.dart';
import 'package:artisan/components/note_dialog.dart';


class ProjectWorkspacePage extends StatefulWidget {
  final String projectName;
  final String projectId;
  final String currentUserEmail;
  const ProjectWorkspacePage({super.key, required this.projectName, required this.projectId, required this.currentUserEmail});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}


class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  bool _isExpanded = false;
  String? _selectedCategory;
  String? _selectedToolbar = "Select Tool";

  /* handles workspace information and project data */
  Map<String, dynamic>? projectData;
  List<DroppedItem> droppedItems = [];
  List<Connection> connections = [];

  final firestoreProjects = FirestoreProjects();
  final firestoreNotifications = FirestoreNotifications();

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }


  /* FUNCTION that reloads the current state and configuration of the project */
  Future<void> _reloadProject() async {
    final project = await firestoreProjects.getProjectById(widget.projectId);
    setState(() { projectData = project; });
  }


  /* FUNCTION that loads workspace information and project data on initial run */
  Future<void> _loadWorkspace() async {
    final workspace = await loadWorkspace(widget.projectId);
    final project = await firestoreProjects.getProjectById(widget.projectId);

    setState(() {
      projectData = project;
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

            /*** TOP BAR ***/
            Container(
              color: const Color.fromARGB(255, 34, 36, 49),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [


                  /*** LEFT TOP BAR ***/
                  InkWell(
                    onTap: () { Navigator.pop(context); },
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/images/logo.svg', height: 30),
                        const SizedBox(width: 8),
                        Text(
                          projectData?['title'] ?? widget.projectName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),


                  /*** RIGHT TOP BAR ***/
                  Row(
                    children: [

                      /*** PROJECT MEMBERS ICON BUTTON ***/
                      GestureDetector(
                        onTap: () {
                          if (projectData == null) return;

                          final owner = projectData!['owner'] ?? "Unknown";
                          final collabs = List<String>.from(projectData!['collabs'] ?? []);
                          final members = [owner, ...collabs];

                          showDialog(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: const Text("Project Members", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final member in members)
                                      Text(
                                        member == owner ? "$member (owner)" : member,
                                        style: TextStyle(fontWeight: member == owner ? FontWeight.bold : FontWeight.normal),
                                      ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Close", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Icon(Icons.group, color: Colors.white),
                      ),

                      const SizedBox(width: 16),


                      /*** SHARE ICON BUTTON ***/
                      /* ensures that only the project owner and collaborators can make changes to the project */
                      if (projectData != null) ...[
                        if (projectData!['owner'] == widget.currentUserEmail || (projectData!['collabs'] as List<dynamic>).contains(widget.currentUserEmail)) ...[
                          GestureDetector(
                            onTap: () {
                              if (projectData == null) return;

                              final TextEditingController emailController = TextEditingController();
                              bool public = projectData!['public'] ?? false;

                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return StatefulBuilder(
                                    builder: (ctx, setState) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        title: const Text("Share Project", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [

                                            /*** ADD MEMBER ***/
                                            const Text("Add Member by Email"),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: emailController,
                                              decoration: InputDecoration(
                                                hintText: "Enter email",
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            /*** TOGGLE PUBLIC ***/
                                            /* ensures that only the project owner can make the project public */
                                            if (projectData?['owner'] == widget.currentUserEmail) ...[
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Make project public"),
                                                  Switch(
                                                    value: public,
                                                    onChanged: (val) { setState(() => public = val); },
                                                  ),
                                                ],
                                              ),
                                            ],

                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text("Cancel", style: TextStyle( color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                          ),

                                          TextButton(
                                            onPressed: () async {

                                              /* adds new collaborator to the project */
                                              final email = emailController.text.trim();
                                              final projectTitle = projectData?['title'] ?? widget.projectName;
                                              final collabs = List<String>.from(projectData?['collabs'] ?? []);

                                              if (email.isNotEmpty) {
                                                await firestoreProjects.addMember(widget.projectId, email);

                                                await firestoreNotifications.createNotification(
                                                  projectName: projectTitle,
                                                  projectId: widget.projectId,
                                                  from: widget.currentUserEmail,  
                                                  recipient: email,                    
                                                  message: "You have been added to project \"$projectTitle\"",
                                                  opened: false,
                                                  date: DateTime.now(),
                                                );
                                              }

                                              /* makes the project go public */
                                              if (public && projectData?['public'] == false) {
                                                await firestoreNotifications.createNotificationsForRecipients(
                                                  projectName: projectTitle,
                                                  projectId: widget.projectId,
                                                  from: widget.currentUserEmail,
                                                  recipients: collabs,
                                                  message: "Project \"$projectTitle\" has been made public",
                                                  date: DateTime.now(),
                                                );
                                              }

                                              await firestoreProjects.updatePublic(widget.projectId, public);

                                              await _reloadProject();

                                              if (mounted) {
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Project settings updated!")),
                                                );
                                              }
                                            },

                                            child: const Text("Save", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: const Icon(Icons.share, color: Colors.white),
                          ),

                          const SizedBox(width: 16),


                          /*** SAVE ICON BUTTON ***/
                          /* saves the current state and configurations of the project */
                          GestureDetector(
                            onTap: () async {
                              await saveWorkspace(widget.projectId, droppedItems, connections);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Workspace saved!")),
                              );
                            },
                            child: const Icon(Icons.save, color: Colors.white),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),


            /*** TOOLBAR ROW ***/
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


            /*** WORKSPACE AREA ***/
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
                                child: Text("Workspace Area", style: TextStyle(color: Color.fromARGB(70, 40, 40, 40))),
                              ),

                              /*** CONNECTION LINES ***/
                              CustomPaint(
                                size: Size.infinite,
                                painter: ConnectionPainter(droppedItems, connections),
                              ),

                              /*** DEVICES ***/
                              ...droppedItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                              return Positioned(
                                left: item.dx,
                                top: item.dy,
                                child: GestureDetector(
                                  onTap: () async {
                                    

                                    /*** DELETE TOOL ***/
                                    if (_selectedToolbar == "Delete") {
                                      final deviceToRemove = droppedItems[index];

                                      /* checks if the device has connections*/
                                      final hasConnections = connections.any((c) => c.fromId == deviceToRemove.id || c.toId == deviceToRemove.id);

                                      /* disables delete if device has any connections */
                                      if (hasConnections) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.error_outline, color: Colors.white),
                                                SizedBox(width: 7),
                                                Expanded(
                                                  child: Text('Cannot delete device with existing connections.', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 3),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }

                                      /* deletes the selected device */
                                      else {
                                        droppedItems.removeAt(index);
                                        setState(() {});
                                      }
                                    }


                                    /*** INSPECT TOOL - NOTE ***/
                                    /* allows to edit and view note */
                                    else if (_selectedToolbar == "Inspect Tool" && item.label == "Note") {
                                      final updatedNote = await showDialog<Map<String, String>>(
                                        context: context,
                                          builder: (ctx) => NoteDialog(
                                            initialTitle: item.noteTitle ?? "Note",
                                            initialMessage: item.noteMessage ?? "",
                                            projectData: projectData!,
                                            projectId: widget.projectId,
                                            currentUserEmail: widget.currentUserEmail,
                                            firestoreNotifications: firestoreNotifications,
                                          ),
                                      );

                                      if (updatedNote != null) {
                                        setState(() {
                                          droppedItems[index] = droppedItems[index].copyWith(
                                            noteTitle: updatedNote['title'],
                                            noteMessage: updatedNote['message'],
                                          );
                                        });
                                      }
                                    }


                                    /*** INSPECT TOOL - PC ***/
                                    /* allows to open menu box for pc */
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
                                          droppedItems: droppedItems,    
                                          connections: connections,       
                                          onConnectionsUpdated: () {     
                                            setState(() {});
                                          },
                                        ),
                                      );

                                      if (updatedPC != null) {
                                        setState(() {
                                          droppedItems[index] = droppedItems[index].copyWith(pcConfig: updatedPC);
                                        });
                                      }
                                    }


                                    /*** INSPECT TOOL - ROUTER ***/
                                    /* allows to open menu box for router */
                                    else if (_selectedToolbar == "Inspect Tool" && item.label.contains("Router")) {
                                      final updatedRouter = await showDialog<RouterDevice>(
                                        context: context,
                                        builder: (ctx) => RouterConfigDialog(
                                          router: item.routerConfig ?? RouterDevice(name: "Router"),
                                          onSave: (router) => Navigator.pop(ctx, router),
                                          droppedItems: droppedItems,
                                          connections: connections,
                                          onConnectionsUpdated: () => setState(() {}), 
                                        ),
                                      );

                                      if (updatedRouter != null) {
                                        setState(() {
                                          droppedItems[index] = droppedItems[index].copyWith(routerConfig: updatedRouter);
                                        });
                                      }
                                    }


                                    /*** INSPECT TOOL - SWITCH ***/
                                    /* allows to open menu box for switch */
                                    else if (_selectedToolbar == "Inspect Tool" && item.label.contains("Switch")) {
                                      final updatedSwitch = await showDialog<SwitchDevice>(
                                        context: context,
                                        builder: (ctx) => SwitchConfigDialog(
                                          sw: item.switchConfig ?? SwitchDevice(name: "Switch"),
                                          onSave: (sw) => Navigator.pop(ctx, sw),
                                          droppedItems: droppedItems,
                                          connections: connections,
                                          onConnectionsUpdated: () => setState(() {}), 
                                        ),
                                      );

                                      if (updatedSwitch != null) {
                                        setState(() {
                                          droppedItems[index] = droppedItems[index].copyWith(switchConfig: updatedSwitch);
                                        });
                                      }
                                    }

                                  },


                                  /*** SELECT TOOL ***/
                                  /* allows devices to be moved around the workspace area */
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


            /*** BOTTOM BAR ***/
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              color: const Color(0xFF1E1F2A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: _isExpanded ? 260 : 65,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        /*** EXPAND BUTTON ***/
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFF2A2B38), borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                            onPressed: () {setState(() {_isExpanded = !_isExpanded;});},
                            icon: Icon(_isExpanded ? Icons.close : Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    /*** BOTTOM BAR CONTENT ***/
                    if (_isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /*** LEFT PANEL ***/
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      /*** NETWORK DEVICES ***/
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

                                      /*** END DEVICES ***/
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

                            /*** RIGHT PANEL ***/
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(color: const Color(0xFF2A2B38), borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.all(12),
                                child: _selectedCategory == null
                                    ? const Center(child: Text("Select a device", style: TextStyle(color: Colors.white54)))
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedCategory!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                          const SizedBox(height: 12),
                                          if (_selectedCategory == "Router") ...[_subOption(Icons.router, "Router")],
                                          if (_selectedCategory == "PC") ...[ _subOption(Icons.computer, "PC")],
                                          if (_selectedCategory == "Server") ...[_subOption(Icons.storage, "Server")],
                                          if (_selectedCategory == "Switch") ...[_subOption(Icons.dns, "Switch")],
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


  /* WIDGET that constructs and perform the logic for the tool bar buttons */
  Widget _toolbarButton(String text) {
    final bool isSelected = _selectedToolbar == text;

    return TextButton(
      onPressed: () {
        setState(() {
          _selectedToolbar = text;
          if (text == "Add Note") { droppedItems.add(DroppedItem(label: "Note", iconCodePoint: Icons.note.codePoint, dx: 100, dy: 100)); }
        });
      },
      child: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.purple : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }


  /* WIDGET that constructs and perform the logic for the device items */
  Widget _deviceItem(IconData icon, String label) {
    final bool isSelected = _selectedCategory == label;

    return InkWell(
      onTap: () { setState(() { _selectedCategory = label; }); },
      child: Column(
        children: [
          Icon(icon, size: 40, color: isSelected ? Colors.purple : Colors.white),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? Colors.purple : Colors.white, fontSize: 14)),
        ],
      ),
    );
  }


  /* WIDGET that displays the icon and name of devices on the right panel */
  Widget _subOption(IconData icon, String name) {
    return Draggable<_DragPayload>(
      data: _DragPayload.newItem(icon, name),
      feedback: _workspaceItem(DroppedItem(label: name, iconCodePoint: icon.codePoint, dx: 0, dy: 0), isDragging: true),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(width: 5),
          Text(name, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }


  /* WIDGET that displays the dragged devices and notes on the workspace area */
  Widget _workspaceItem(DroppedItem item, {bool isDragging = false}) {
    final displayText = item.label == "Note" && item.noteTitle != null ? item.noteTitle! : item.label;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDragging ? const Color.fromARGB(160, 55, 55, 55) : const Color.fromARGB(255, 55, 55, 55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: item.label == "Note" ? const Color.fromARGB(153, 255, 235, 59) : Colors.white,
            size: item.label == "Note" ? 28 : 44,
          ),

          SizedBox(
            width: 65, 
            child: Text(
              displayText,
              style: TextStyle(
                color: item.label == "Note" ? const Color.fromARGB(153, 255, 235, 59) : Colors.white,
                fontSize: item.label == "Note" ? 9 : 10,
                fontWeight: item.label == "Note" ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),

          if (item.label == "PC" && item.pcConfig != null) ...[
            Text(item.pcConfig!.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 9)),
          ],

          if (item.label.contains("Router") && item.routerConfig != null) ...[
            Text(item.routerConfig!.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 9)),
          ],

          if (item.label.contains("Switch") && item.switchConfig != null) ...[
            Text(item.switchConfig!.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 9)),
          ],

        ],
      ),
    );
  }
}





/// --------------------------------
/// DRAGGABLES
/// --------------------------------

/* CLASS that represents an item dropped on the canvas (PC, Router, Switch, or Note) */
class DroppedItem {
  final String id;
  final String label;
  final int iconCodePoint;
  final double dx;
  final double dy;

  final PCDevice? pcConfig;
  final RouterDevice? routerConfig;
  final SwitchDevice? switchConfig; 
  final String? noteTitle;
  final String? noteMessage;

  DroppedItem({
    String? id,
    required this.label,
    required this.iconCodePoint,
    required this.dx,
    required this.dy,
    this.pcConfig,
    this.routerConfig,
    this.switchConfig, 
    this.noteTitle,
    this.noteMessage,
  }) : id = id ?? const Uuid().v4();

  /* converts stored icon code point to an IconData */
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /* creates a copy of the object with updated fields */
  DroppedItem copyWith({
    String? label,
    int? iconCodePoint,
    double? dx,
    double? dy,
    PCDevice? pcConfig,
    RouterDevice? routerConfig,
    SwitchDevice? switchConfig, 
    String? noteTitle,
    String? noteMessage,
  }) {
    return DroppedItem(
      id: id,
      label: label ?? this.label,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      pcConfig: pcConfig ?? this.pcConfig,
      routerConfig: routerConfig ?? this.routerConfig,
      switchConfig: switchConfig ?? this.switchConfig,  
      noteTitle: noteTitle ?? this.noteTitle,
      noteMessage: noteMessage ?? this.noteMessage,
    );
  }

  /* converts object into a Map for storage */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'iconCodePoint': iconCodePoint,
      'dx': dx,
      'dy': dy,
      'pcConfig': pcConfig?.toMap(),
      'routerConfig': routerConfig?.toMap(),
      'switchConfig': switchConfig?.toMap(), 
      'noteTitle': noteTitle,
      'noteMessage': noteMessage,
    };
  }

  /* rebuilds a DroppedItem from a map */
  factory DroppedItem.fromMap(Map<String, dynamic> map) {
    return DroppedItem(
      id: map['id'] as String?,
      label: map['label'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      dx: (map['dx'] as num).toDouble(),
      dy: (map['dy'] as num).toDouble(),
      pcConfig: map['pcConfig'] != null
          ? PCDevice.fromMap(Map<String, dynamic>.from(map['pcConfig']))
          : null,
      routerConfig: map['routerConfig'] != null
          ? RouterDevice.fromMap(Map<String, dynamic>.from(map['routerConfig']))
          : null,
      switchConfig: map['switchConfig'] != null 
          ? SwitchDevice.fromMap(Map<String, dynamic>.from(map['switchConfig']))
          : null,
      noteTitle: map['noteTitle'] as String?,
      noteMessage: map['noteMessage'] as String?,
    );
  }
}


/* CLASS for payload wrapper used when dragging items (either new or existing) */
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


/* FUNCTION that safely finds a DroppedItem in list by ID */
DroppedItem? safeFind(List<DroppedItem> items, String id) {
  try {
    return items.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
}





/// --------------------------------
/// CONNECTIONS
/// --------------------------------

/* CLASS that represents a connection (edge) between two dropped items by ID */
class Connection {
  final String fromId;
  final String toId;

  Connection(this.fromId, this.toId);

  Map<String, dynamic> toMap() => {'from': fromId, 'to': toId};
  factory Connection.fromMap(Map<String, dynamic> map) => Connection(map['from'] as String, map['to'] as String);
}


/* CLASS for custom painter on drawing connections between items on canvas */
class ConnectionPainter extends CustomPainter {
  final List<DroppedItem> items;
  final List<Connection> connections;

  ConnectionPainter(this.items, this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(255, 34, 36, 49)
      ..strokeWidth = 3;

    for (var conn in connections) {
      final fromIndex = items.indexWhere((i) => i.id == conn.fromId);
      final toIndex = items.indexWhere((i) => i.id == conn.toId);

      if (fromIndex == -1 || toIndex == -1) continue;

      final from = items[fromIndex];
      final to = items[toIndex];

      final fromOffset = Offset(from.dx + 40, from.dy + 40); 
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

/* CLASS that holds items + connections for a workspace */
class WorkspaceData {
  final List<DroppedItem> items;
  final List<Connection> connections;
  WorkspaceData({required this.items, required this.connections});
}


/* FUNCTION that saves workspace state (items + connections) to Firestore */
Future<void> saveWorkspace(String projectId, List<DroppedItem> items, List<Connection> connections) async {
  final ref = FirebaseFirestore.instance.collection('workspaces').doc(projectId);
  final firestoreProjects = FirestoreProjects();
  await firestoreProjects.updateDateModified(projectId);
  await ref.set({
    'items': items.map((e) => e.toMap()).toList(),
    'connections': connections.map((c) => c.toMap()).toList(),
  });
}


/* FUNCTION that loads workspace state (items + connections) from Firestore */
Future<WorkspaceData> loadWorkspace(String projectId) async {
  final ref = FirebaseFirestore.instance.collection('workspaces').doc(projectId);
  final snap = await ref.get();

  if (!snap.exists) return WorkspaceData(items: [], connections: []);

  final data = snap.data() as Map<String, dynamic>;
  final rawItems = (data['items'] as List?) ?? [];
  final rawConnections = (data['connections'] as List?) ?? [];

  final items = rawItems.map((e) => DroppedItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  final conns = rawConnections.map((e) => Connection.fromMap(Map<String, dynamic>.from(e as Map))).toList();

  restoreConnections(items, conns);

  return WorkspaceData(items: items, connections: conns);
}


/* FUNCTION that rebuilds logical device connections (e.g., PC↔Router) after loading */
void restoreConnections(List<DroppedItem> droppedItems, List<Connection> connections) {
  for (final conn in connections) {
    final fromItem = safeFind(droppedItems, conn.fromId);
    final toItem = safeFind(droppedItems, conn.toId);

    if (fromItem == null || toItem == null) continue;

    /* matches possible device connection pairs */
    if (fromItem.pcConfig != null && toItem.routerConfig != null) {
      connectPCToRouter(fromItem.pcConfig!, toItem.routerConfig!);
    }
    
    else if (fromItem.routerConfig != null && toItem.pcConfig != null) {
      connectPCToRouter(toItem.pcConfig!, fromItem.routerConfig!);
    }
    
    else if (fromItem.routerConfig != null && toItem.routerConfig != null) {
      connectRouterToRouter(fromItem.routerConfig!, toItem.routerConfig!);
    }
    
    else if (fromItem.pcConfig != null && toItem.switchConfig != null) {
      connectPCToSwitch(fromItem.pcConfig!, toItem.switchConfig!);
    }
    
    else if (fromItem.switchConfig != null && toItem.pcConfig != null) {
      connectPCToSwitch(toItem.pcConfig!, fromItem.switchConfig!);
    }
    
    else if (fromItem.routerConfig != null && toItem.switchConfig != null) {
      connectRouterToSwitch(fromItem.routerConfig!, toItem.switchConfig!);
    }
    
    else if (fromItem.switchConfig != null && toItem.routerConfig != null) {
      connectRouterToSwitch(toItem.routerConfig!, fromItem.switchConfig!);
    }
    
    else if (fromItem.switchConfig != null && toItem.switchConfig != null) {
      connectSwitchToSwitch(fromItem.switchConfig!, toItem.switchConfig!);
    }
  }
}