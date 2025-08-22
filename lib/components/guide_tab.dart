import 'package:flutter/material.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A), // Dark background
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            // FAQ Section
            _buildSection("Frequently Asked Questions", [
              {
                "title": "What is Cisco Packet Tracer?",
                "desc":
                    "A powerful network simulation tool used to design, configure, and troubleshoot networks."
              },
              {
                "title": "Is Packet Tracer free?",
                "desc":
                    "Yes. It is free for Cisco Networking Academy students and available for download after registration."
              },
              {
                "title": "Can Packet Tracer replace real hardware?",
                "desc":
                    "No. It is mainly for learning and practice, not a full replacement for physical devices."
              },
            ]),

            // Network Devices Section
            _buildSection("Network Devices", [
              {
                "title": "Hubs",
                "desc": "Broadcast data it receives to all connected devices."
              },
              {
                "title": "Routers",
                "desc": "Forward data packets between different networks based on IP addresses."
              },
              {
                "title": "Switches",
                "desc": "Send data directly to the specific device (based on MAC addresses)."
              },
              {
                "title": "Wireless Router",
                "desc": "Provides Wi-Fi connectivity and routing functions for devices."
              },
              {
                "title": "Access Points",
                "desc":
                    "Extends wireless coverage, connecting devices to a wired network."
              },
            ]),

            // End Devices
            _buildSection("End Devices", [
              {
                "title": "PCs",
                "desc": "General end-user computers used to test and configure networks."
              },
              {
                "title": "Laptops",
                "desc": "Portable end devices for network testing and simulation."
              },
              {
                "title": "Servers",
                "desc":
                    "Provide services like DHCP, DNS, HTTP, Email, or FTP in simulations."
              },
              {
                "title": "Smartphones/Tablets",
                "desc": "Used to simulate mobile clients in a network."
              },
              {
                "title": "Printers",
                "desc": "Can be network-connected to simulate shared resources."
              },
            ]),

            // Connections
            _buildSection("Connections", [
              {
                "title": "Copper Straight-Through",
                "desc": "Used to connect different devices (PC to Switch, Router to Switch)."
              },
              {
                "title": "Copper Cross-Over",
                "desc": "Used to connect similar devices (PC to PC, Switch to Switch)."
              },
              {
                "title": "Fiber Optic",
                "desc": "High-speed connections for switches, routers, and servers."
              },
              {
                "title": "Console Cable",
                "desc": "Used to configure routers and switches via CLI."
              },
              {
                "title": "Wireless",
                "desc": "Used to connect Wi-Fi enabled devices to access points or routers."
              },
            ]),

            // Types of View
            _buildSection("Types of View", [
              {
                "title": "Logical View",
                "desc": "Shows devices, connections, and topology at the network level."
              },
              {
                "title": "Physical View",
                "desc":
                    "Represents racks, rooms, and the physical placement of devices."
              },
              {
                "title": "Realtime Mode",
                "desc":
                    "Displays live packet movement and simulates real-time operations."
              },
              {
                "title": "Simulation Mode",
                "desc":
                    "Lets you pause, replay, and analyze packet flow step-by-step."
              },
            ]),

            // Tool Bar
            _buildSection("Tool Bar", [
              {
                "title": "Select Tool",
                "desc": "Used to select and move devices."
              },
              {
                "title": "Delete Tool",
                "desc": "Removes devices or connections from the workspace."
              },
              {
                "title": "Inspect Tool",
                "desc": "Opens a device to configure settings (CLI or GUI)."
              },
              {
                "title": "Add Simple PDU",
                "desc": "Used to test connectivity (like a simple ping)."
              },
              {
                "title": "Add Complex PDU",
                "desc": "Creates custom traffic flows to test advanced configurations."
              },
            ]),
          ],
        ),
      ),
    );
  }

  // Reusable Section Builder
  Widget _buildSection(String title, List<Map<String, String>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title + Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"]!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item["desc"]!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Learn More Button
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to a detail page for this item
                  },
                  child: const Text(
                    "Learn More",
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
