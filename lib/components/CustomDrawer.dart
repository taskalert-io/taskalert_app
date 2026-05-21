// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:gulf_app/screens/congratulations.dart';
// import 'package:gulf_app/screens/selcet_booking_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// import '../screens/TermsAndConditionsScreen.dart';
// import '../screens/new_test_cart.dart';
// import '../screens/parchase_giftcard_one.dart';

class CustomDrawer extends StatefulWidget {
  final String activeTile;
  final Function(String) onTileTap;

  const CustomDrawer({
    super.key,
    required this.activeTile,
    required this.onTileTap,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String activeTile = '';
  String loggedInUserName = '';

  @override
  void initState() {
    super.initState();
    activeTile = widget.activeTile;
    _loadUserName(); // Load the user name when the widget is initialized
  }

  void _loadUserName() async {
    String? userName = await getUserName();
    setState(() {
      loggedInUserName = userName ?? "Amit Kumar Mandal"; // Provide a fallback value
    });
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name'); // Returns userId if stored, else null
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the dynamically stored API URL and auth token from SharedPreferences
    const String apiUrl =
        'https://wealthclockadvisors.com/api/client/logout'; // Replace with your actual API URL
    final String? authToken =
    prefs.getString('auth_token'); // Dynamically get the auth token

    // Check if the auth token is null
    if (authToken == null) {
      // print('Auth token not found in SharedPreferences');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Unable to retrieve session data. Please log in again.')),
      );
      return;
    }

    try {
      // print('Attempting to log out...');
      // print('API URL: $apiUrl');
      // print('Authorization Token: $authToken');

      // Sending the GET request to the logout API
      final response = await http.get(
        Uri.parse('$apiUrl?logout=true'),
        headers: {
          'Authorization': 'Bearer $authToken', // Use the dynamic auth token
          'Content-Type': 'application/json',
        },
      );

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Successfully logged out
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!')),
        );

        // Clear all session data after logout
        await prefs.clear();

        // Navigate to the login screen after successful logout
        Navigator.pushReplacementNamed(context, '/login');
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized')),
        );
      } else {
        // Handle API error response
        // print('Error during logout. Status code: ${response.statusCode}');
        // print('Error body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to logout. Please try again.'),
          ),
        );
      }
    } catch (e) {
      // Handle network or other errors
      // print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to log out. $e'),
        ),
      );
    }
  }

  // Widget _buildDrawerTile({
  //   required String title,
  //   required IconData icon,
  // }) {
  //   bool isActive = activeTile == title;
  //   return Container(
  //     decoration: BoxDecoration(
  //       border:
  //           Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.0)),
  //     ),
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(
  //         padding: EdgeInsets.zero,
  //         backgroundColor: isActive ? Color(0xFFfee0be) : Colors.transparent,
  //         elevation: isActive ? 5 : 0,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  //       ),
  //       onPressed: () {
  //         setState(() {
  //           activeTile = title;
  //         });
  //         widget.onTileTap(title);
  //         Navigator.pop(context); // Close drawer
  //       },
  //       child: ListTile(
  //         leading: Icon(
  //           icon,
  //           color: isActive ? Color(0xFF0f625c) : Color(0xFF303131),
  //           size: 20,
  //         ),
  //         title: Text(
  //           title,
  //           style: TextStyle(
  //             color: isActive ? Color(0xFF0f625c) : Color(0xFF303131),
  //             fontSize: 15,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDrawerTile({
    required String title,
    required IconData icon,
    Widget? destinationScreen,
  }) {
    bool isActive = activeTile == title;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close drawer

        if (activeTile == title) {
          // ✅ Don't navigate if already on this screen
          return;
        }
        setState(() {
          activeTile = title;
        });
        widget.onTileTap(title);

        if (destinationScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationScreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title screen is under development!')),
          );
        }

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => destinationScreen),
        // );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ?  const Color(0xFF7DB778) : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFBFEBBC), width: 1.0),
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isActive ? const Color(0xFF9ECF9A) : const Color(0xFF669933),width: 1)
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFffffff) : const Color(0xFFffffff),
                size: 22, // Slightly increased for better visibility
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFFffffff) : const Color(0xFFffffff),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF9ECF9A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF9ECF9A)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 5,
                        children: [
                          const Icon(Icons.arrow_back_ios_sharp,size: 19,color: Color(0xFFffffff),),
                          Text("Jester Park Golf Course",style: GoogleFonts.poppins(color: const Color(0xFFFFFFFF),fontSize: 16,fontWeight: FontWeight.w600),)
                        ],
                      ),
                    ),
                    const SizedBox(height: 40,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/menu_ppl.png',
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 200,
                              child: Text(
                                loggedInUserName,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFFFFFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(top: 5),
                              width: 200,
                              child: Text(
                                '+ 91 87777 94755',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFFFFFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Drawer Items
            _buildDrawerTile(
              title: 'Home',
              icon: Icons.home,
              // destinationScreen: const SelcetBookingClass(userId: ''),
            ),
            _buildDrawerTile(
              title: 'My Profile',
              icon: Icons.person_outline_sharp,
            ),
            _buildDrawerTile(
              title: 'Tee Times',
              icon: Icons.golf_course_outlined,
            ),
            _buildDrawerTile(
              title: 'My Transactions',
              icon: Icons.receipt_long,
            ),
            _buildDrawerTile(
              title: 'My Reservations',
              icon: Icons.calendar_month_sharp,
            ),
            _buildDrawerTile(
              title: 'My Wallet',
              icon: Icons.shopping_cart,
            ),
            _buildDrawerTile(
              title: 'Gift Card',
              icon: Icons.card_giftcard,
            ),
            _buildDrawerTile(
              title: 'Parchase Gift Card',
              icon: Icons.add_card_outlined,
              // destinationScreen: const ParchaseGiftCardOnePage(pgCardId: ''),
            ),
            _buildDrawerTile(
              title: 'New Testing Cart',
              icon: Icons.add_card_outlined,
              // destinationScreen: const NewTestCartPage(nwTstId: ''),
            ),
            _buildDrawerTile(
              title: 'Congratulations!',
              icon: Icons.event_available,
              // destinationScreen: const CongratulationsPage(cngsId: ''),
            ),
            _buildDrawerTile(
              title: 'Terms & Conditions',
              icon: Icons.event_available,
              // destinationScreen: const TermsAndConditionsScreen(tncId: ''),
            ),
            // Logout Button
            Container(
              margin: const EdgeInsets.only(top: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      child: Stack(
                          children: [
                            SizedBox(
                              width: 260,
                              child: ElevatedButton(
                                onPressed: () => _logout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF244065),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(top: 14,right: 12,child: Icon(Icons.arrow_forward,color: Color(0xFFffffff),size: 20,)),
                          ]
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
