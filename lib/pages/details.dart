import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final int index;
  const DetailsPage({super.key, required this.index});

  /* holds information to be presented based on index */
  static final List<Map<String, String>> detailsData = [
    {
      "title": "How to use Artisan app?",
      "desc": "A.R.T.I.S.A.N. which stands for \"Accessible Routing and Topology Interactive Simulation for Applied Networking\" is a mobile network simulator that lets you create virtual topologies by adding PCs, routers, switches, and servers. \n\nYou can connect these devices, configure them using Cisco IOS commands, and test connectivity through tools like ping or traceroute. \n\nProjects can also be saved, shared, and even made public for others to explore.",
      "image": 'assets/detail_images/how_to_use.png'
    },
    {
      "title": "Why use Artisan app?",
      "desc": "Artisan provides a convenient way to practice networking concepts anytime, anywhere without needing expensive physical equipment. \n\nIt’s free to use, accessible to students and professionals, and designed to help users strengthen their configuration and troubleshooting skills while also exploring community-shared projects.",
      "image": 'assets/detail_images/why_artisan.png'
    },
    {
      "title": "Is Artisan equal to real hardware?",
      "desc": "While Artisan offers a realistic simulation of Cisco devices, it is primarily intended for learning and practice. It does not fully replace physical routers, switches, or servers, but it helps users build a strong foundation before working with actual hardware in labs or industry settings.",
      "image": 'assets/detail_images/replacement.png'
    },
    {
      "title": "About the developer",
      "desc": "A.R.T.I.S.A.N. which stands for \"Accessible Routing and Topology Interactive Simulation for Applied Networking\" is developed by Sean Kierby Concepcion, a BS Computer Science Student at the University of the Philippines Los Banos. \n\nHe is a proud member of the Graphic Literature Guild (GLG) and Game Development Society (GDS). \n\nHis work mostly revolves around mobile application and web development, as well as doing 2D game development at his personal leisure.",
      "image": 'assets/detail_images/about.png'
    },


    {
      "title": "Router Device",
      "desc": "Routers in Artisan can be configured with Cisco IOS commands to handle IP addressing, static and dynamic routing, and inter-network communication. \n\nThey play a central role in directing traffic between devices and simulating real-world enterprise or home network setups. \n\nNOTE: During simulation, a name must be applied to the device before configuration.",
      "image": 'assets/detail_images/router.png'
    },
    {
      "title": "Switch Device",
      "desc": "Switches allow you to connect multiple devices within the same network and manage VLAN configurations. \n\nIn Artisan, switches are essential for building LANs, testing connectivity between hosts, and practicing common tasks such as port configuration or troubleshooting collisions. \n\nNOTE: During simulation, a name must be applied to the device before configuration.",
      "image": 'assets/detail_images/switch.png'
    },


    {
      "title": "PC Device",
      "desc": "PCs act as end devices in your virtual network. You can assign IP addresses, test connectivity with pings, and use them to validate routing or switching configurations. \n\nThey are useful for simulating client machines in different topologies. \n\nNOTE: During simulation, a name must be applied to the device before configuration.",
      "image": 'assets/detail_images/pc.png'
    },
    {
      "title": "Server Device",
      "desc": "Servers in Artisan can be used to simulate services such as DHCP, DNS, or web hosting. \n\nThey provide an excellent way to understand how networked applications rely on server-side configurations and how clients interact with them in real-world scenarios. \n\nNOTE: During simulation, a name must be applied to the device before configuration.",
      "image": 'assets/detail_images/server.png'
    },


    {
      "title": "Select Tool",
      "desc": "The Select Tool allows you to pick and move devices or connections within your network topology. \n\nThis makes it easy to rearrange your design, organize layouts, and keep your project neat and easy to understand.",
      "image": 'assets/detail_images/select.png'
    },
    {
      "title": "Inspect Tool",
      "desc": "The Inspect Tool lets you open a device’s configuration panel or console. \n\nWith it, you can view settings, run commands, and edit configurations, giving you full control over how each device behaves in your simulated network.",
      "image": 'assets/detail_images/inspect.png'
    },
    {
      "title": "Delete Tool",
      "desc": "The Delete Tool is used to remove devices, links, or notes from your workspace. \n\nIt helps keep your project clean and ensures you can quickly fix mistakes or reconfigure your network design without hassle. \n\nNOTE: Only devices with no connection are eligible to be deleted.",
      "image": 'assets/detail_images/delete.png'
    },
    {
      "title": "Add Note Tool",
      "desc": "The Add Note Tool lets you place custom notes directly on your project canvas. \n\nNotes are useful for labeling devices, describing network segments, or leaving reminders for yourself or others when sharing your topology.",
      "image": 'assets/detail_images/add_note.png'
    },

    {
      "title": "PC Commands",
      "desc": "clear → Clear console\n\n ping <targetIP> → Test connectivity",
      "image": 'assets/detail_images/pc.png'
    },
    {
      "title": "Switch Commands",
      "desc": "show mac → Display MAC table of connected devices\n\n show vlan → Display VLAN assignments\n\n set vlan <port> <id> → Assign VLAN to a port\n\n clear → Clear console\n\n help → Show available commands",
      "image": 'assets/detail_images/switch.png'
    },
    {
      "title": "Router Commands (User Mode)",
      "desc": "enable → Enter Privileged Mode\n\n clear → Clear console",
      "image": 'assets/detail_images/router.png'
    },
    {
      "title": "Router Commands (Privileged Mode)",
      "desc": "configure terminal → Enter Global Config Mode\n\n show ip → Display interface IPs\n\n show ip route → Display routing table\n\n show connections → Show connections on all ports\n\n copy running-config startup-config → Save configuration\n\n disable → Return to User Mode",
      "image": 'assets/detail_images/router.png'
    },
    {
      "title": "Router Commands (Global Mode)",
      "desc": "interface <name> → Enter Interface Config Mode\n\n ip route <dest> <mask> <gateway> → Add static route\n\n exit → Return to Privileged Mode",
      "image": 'assets/detail_images/router.png'
    },
    {
      "title": "Router Commands (Interface Mode)",
      "desc": "ip address <ip> <subnet> → Assign IP to interface\n\n no shutdown → Enable interface\n\n exit → Return to Global Config Mode",
      "image": 'assets/detail_images/router.png'
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /*** IMAGE ***/
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item["image"]!,
                          height: MediaQuery.of(context).size.height * 0.15, 
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /*** TITLE AND DESCRIPTION ***/
                      Text(
                        item["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Container(height: 2, width: 300, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                      ),

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

