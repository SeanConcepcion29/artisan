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
            _buildSection("Frequently Asked Questions", []),

            // Network Devices Section
            _buildSection("Network Devices", [
              {
                "title": "Hubs",
                "desc": "Broadcast data it receives to all devices.",
              },
              {
                "title": "Routers",
                "desc": "Forwards data packets based on IP addresses.",
              },
              {
                "title": "Switches",
                "desc": "Sends data directly to specific devices.",
              },
            ]),

            // End Devices
            _buildSection("End Devices", []),

            // Connections
            _buildSection("Connections", []),

            // Types of View
            _buildSection("Types of View", []),

            // Tool Bar
            _buildSection("Tool Bar", []),
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
