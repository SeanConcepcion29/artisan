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
      title: const Text("PC Options"),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showConfig && !showPing) ...[
              ElevatedButton(
                onPressed: () => setState(() {
                  showConfig = true;
                }),
                child: const Text("Configure"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() {
                  showPing = true;
                }),
                child: const Text("Ping"),
              ),
            ],
            if (showConfig) _buildConfigForm(),
            if (showPing) _buildPingUI(),
          ],
        ),
      ),
      actions: [
        if (showConfig || showPing)
          TextButton(
            onPressed: () => setState(() {
              showConfig = false;
              showPing = false;
            }),
            child: const Text("Back"),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
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
