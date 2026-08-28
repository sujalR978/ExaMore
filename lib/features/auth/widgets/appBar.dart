import 'package:flutter/material.dart';

class CustomAppbar extends StatefulWidget {
  final String text;
  const CustomAppbar({super.key, required this.text});

  @override
  State<CustomAppbar> createState() => _AppbarState();
}

class _AppbarState extends State<CustomAppbar> {
  @override
  Widget build(BuildContext context) {
    return 
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100), // Perfect capsule shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                title:  Text(
                  widget.text,
                  style: TextStyle(
                    color: Color(0xFF1E1B4B),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
              ),
            ),
          ),
        ),
      
    );
  }
}
