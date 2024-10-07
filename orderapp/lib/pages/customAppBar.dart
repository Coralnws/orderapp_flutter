import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final String abbreviation;
  final List<Widget>? actions;

  CustomAppBar({
    required this.title,
    required this.userName,
    required this.abbreviation,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color.fromRGBO(0, 160, 247, 1.0),
      elevation: 0.0,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      actions: actions,

      titleSpacing: -15,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        color: Colors.white,
        iconSize: 20,
        onPressed: () {
          Navigator.pop(context);
        },
      ),


      flexibleSpace: Stack(
        children: [
          Positioned(
            right: 40,
            bottom: 12,
            child: Row(
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    _showPopupMenu(context, details.globalPosition);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Text(
                      abbreviation,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
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

  void _showPopupMenu(BuildContext context, Offset position){
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem<int>(
          value: 0,
          child: Text('Profile'),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Text('Logout'),
        ),
      ],
      elevation: 8.0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
