import 'package:flutter/material.dart';

class Googlebutton extends StatefulWidget {
  const Googlebutton({super.key});

  @override
  State<Googlebutton> createState() => _GooglebuttonState();
}

class _GooglebuttonState extends State<Googlebutton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(width: 1, color: Color(0xffCBC4D2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Image.asset('assets/icons/google.png'),
          ),
          SizedBox(width: 13),
          SizedBox(
            child: Text(
              "Continue with Google",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff0B1C30),
                fontWeight: FontWeight(600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
