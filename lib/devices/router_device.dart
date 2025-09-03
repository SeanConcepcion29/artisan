import 'package:flutter/material.dart';

class RouterDevice {
  String name;

  RouterDevice({
    required this.name,
  });

  // Firestore serialization (future use)
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
}

class RouterConfigDialog extends StatefulWidget {
  final RouterDevice router;
  final void Function(RouterDevice router) onSave;

  const RouterConfigDialog({
    super.key,
    required this.router,
    required this.onSave,
  });

  @override
  State<RouterConfigDialog> createState() => _RouterConfigDialogState();
}

class _RouterConfigDialogState extends State<RouterConfigDialog> {
  late TextEditingController nameController;

  bool showConfig = false;
  bool showConsole = false;
  bool showConnections = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.router.name);
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    showConfig = true;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 34, 36, 49), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), 
                    ),
                  ),
                  child: const Text(
                    "Configure",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    showConsole = true;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 34, 36, 49), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Make button rounded
                    ),
                  ),
                  child: const Text(
                    "Console",
                    style: TextStyle(color: Colors.white), 
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    showConnections = true;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 34, 36, 49), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Make button rounded
                    ),
                  ),
                  child: const Text(
                    "Connections",
                    style: TextStyle(color: Colors.white), 
                  ),
                ),
              ),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final updatedRouter = RouterDevice(name: nameController.text);
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
      child: Text(
        "Console feature coming soon!",
        style: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  Widget _buildConnectionsUI() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        "Connections feature coming soon!",
        style: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }
}
