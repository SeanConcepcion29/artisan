import 'package:flutter/material.dart';
import 'package:artisan/pages/details.dart';


class GuidePage extends StatelessWidget {
  const GuidePage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A), // Dark background
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: ListView(
          children: [
            
            /*** FREQUENTLY ASKED QUESTIONS ***/
            _buildSection(context, "Frequently Asked Questions", [
              { "index": 0, "title": "What is Cisco Packet Tracer?" },
              { "index": 1, "title": "Is Packet Tracer free?" },
              { "index": 2, "title": "Can Packet Tracer replace real hardware?" }
            ]),

            /*** NETWORK DEVICES ***/
            _buildSection(context, "Network Devices", [
              { "index": 3, "title": "Router Device" },
              { "index": 4, "title": "Switch Device" }
            ]),

            /*** END DEVICES ***/
            _buildSection(context, "End Devices", [
              { "index": 5, "title": "PC Device" },
              { "index": 6, "title": "Server Device" }
            ]),

            /*** TOOL BAR ***/
            _buildSection(context, "Tool Bar", [
              { "index": 7, "title": "Select Tool" },
              { "index": 8, "title": "Inspect Tool" },
              { "index": 9, "title": "Delete Tool" },
              { "index": 10, "title": "Add Note Tool" }
            ]),

          ],
        ),
      ),
    );
  }


  /* WIDGET for the guide cards */
  Widget _buildSection(BuildContext context, String title, List<Map<String, dynamic>> items) {
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
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Container(
            margin: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 4,
              bottom: index == items.length - 1 ? 16 : 4, 
            ),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                
                /*** TITLE ***/
                Expanded(
                  child: Text(
                    item["title"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),

                /*** LEARN MORE ***/
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(index: item["index"]),
                      ),
                    );
                  },
                  child: const Text(
                    "Learn More",
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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