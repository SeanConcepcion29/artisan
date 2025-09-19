import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final int index;
  const DetailsPage({super.key, required this.index});


  /* holds information to be presented based on index */
  static final List<Map<String, String>> detailsData = [
    {
      "title": "What is Cisco Packet Tracer?",
      "desc": "A powerful network simulation tool used to design, configure, and troubleshoot networks.",
      "image": 'assets/detail_images/icon.png'
    },
    {
      "title": "Is Packet Tracer free?",
      "desc": "Yes. It is free for Cisco Networking Academy students and available for download after registration.",
      "image": 'assets/detail_images/router.png'
    },
    {
      "title": "Can Packet Tracer replace real hardware?",
      "desc": "No. It is mainly for learning and practice, not a full replacement for physical devices.",
      "image": 'assets/detail_images/router.png'
    },


    {
      "title": "Router Device",
      "desc": "A powerful network simulation tool used to design, configure, and troubleshoot networks.",
      "image": 'assets/detail_images/router.png'
    },
    {
      "title": "Switch Device",
      "desc": "Yes. It is free for Cisco Networking Academy students and available for download after registration.",
      "image": 'assets/detail_images/swtich.png'
    },


    {
      "title": "PC Device",
      "desc": "A powerful network simulation tool used to design, configure, and troubleshoot networks.",
      "image": 'assets/detail_images/pc.png'
    },
    {
      "title": "Server Device",
      "desc": "Yes. It is free for Cisco Networking Academy students and available for download after registration.",
      "image": 'assets/detail_images/server.png'
    },


    {
      "title": "Select Tool",
      "desc": "A powerful network simulation tool used to design, configure, and troubleshoot networks.",
      "image": 'assets/detail_images/select.png'
    },
    {
      "title": "Inspect Tool",
      "desc": "Yes. It is free for Cisco Networking Academy students and available for download after registration.",
      "image": 'assets/detail_images/inspect.png'
    },
        {
      "title": "Delete Tool",
      "desc": "A powerful network simulation tool used to design, configure, and troubleshoot networks.",
      "image": 'assets/detail_images/delete.png'
    },
    {
      "title": "Add Note Tool",
      "desc": "Yes. It is free for Cisco Networking Academy students and available for download after registration.",
      "image": 'assets/detail_images/add_note.png'
    },
  ];


  @override
  Widget build(BuildContext context) {
    final item = detailsData[index];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [

            /*** TOP BAR ***/
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  /*** LEFT PROJECT SETTING ICON ***/
                  Icon(
                    Icons.hexagon_outlined,
                    color: Color.fromRGBO(255, 255, 255, 0.4),
                    size: 28,
                  ),

                  /*** APP TITLE ***/
                  const Text(
                    "ARTISAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 16,
                    ),
                  ),

                  /*** RIGHT ACCOUNT SETTING ICON ***/
                  Icon(
                    Icons.account_circle_outlined,
                    color: Color.fromRGBO(255, 255, 255, 0.4),
                    size: 28,
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),


            /*** DESCRIPTION CARD ***/
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start, 
                    children: [

                      /*** IMAGE ***/
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item["image"]!,
                          height: MediaQuery.of(context).size.height * 0.2, 
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /*** TITLE AND DESCRIPTION ***/
                      Text(
                        item["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        item["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),


      /*** BOTTOM NAVIGATION BAR ***/
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1F2A),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end, 
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.undo, color: Colors.white, size: 28),
                  Text("Back", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

