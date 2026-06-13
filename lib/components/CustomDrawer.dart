import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDrawer extends StatefulWidget {
  final String activeTile;
  final Function(String) onTileTap;

  const CustomDrawer({
    super.key,
    required this.activeTile,
    required this.onTileTap,
  });

  @override
}

class _CustomDrawerState extends State<CustomDrawer> {
  String activeTile = '';

  @override
  void initState() {
    super.initState();
    activeTile = widget.activeTile;
  }

    setState(() {
    });
  }

    required String title,
    required IconData icon,
    Widget? destinationScreen,
  }) {

          onTap: () {
            setState(() {
              activeTile = title;
            });
            widget.onTileTap(title);

            if (destinationScreen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destinationScreen),
              );
            }
          },
          child: AnimatedContainer(
            decoration: BoxDecoration(
            ),
                  icon,
                ),
                    title,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                        ),
                        ),
                              children: [
                                  child: Text(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                                child: Text(
                                  ),
                                ),
                              ),
                            ],
                      ),
                      ),
                          ),
                            ),
                          ),
                      ),
                    ),
                  ),
                ),
            ),
          ),
          Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
