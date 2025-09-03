import 'package:flutter/material.dart';

class PCDevice {
  String name;
  String ipAddress;
  String subnetMask;
  String defaultGateway;

  PCDevice({
    required this.name,
    required this.ipAddress,
    this.subnetMask = "255.255.255.0", // ✅ Default mask
    required this.defaultGateway,
  });

  // For Firestore serialization
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

  const PCConfigDialog({super.key, required this.pc, required this.onSave});

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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.pc.name);
    ipController = TextEditingController(text: widget.pc.ipAddress);
    maskController = TextEditingController(
      text: widget.pc.subnetMask.isNotEmpty
          ? widget.pc.subnetMask
          : "255.255.255.0",
    );
    gatewayController = TextEditingController(text: widget.pc.defaultGateway);
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
                    showPing = true;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 34, 36, 49), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Make button rounded
                    ),
                  ),
                  child: const Text(
                    "Ping",
                    style: TextStyle(color: Colors.white), // Change font color
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
            if (showPing) _buildPingUI(),
            if (showConnections) _buildConnectionsUI(),
          ],
        ),
      ),
      actions: [
        if (showConfig || showPing || showConnections)
          TextButton(
            onPressed: () => setState(() {
              showConfig = false;
              showPing = false;
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
        _field("PC Name:", nameController),
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
      child: Text(
        "Ping feature coming soon!",
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

  Widget _field(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}
