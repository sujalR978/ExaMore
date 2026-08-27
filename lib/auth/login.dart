import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundImage: AssetImage('assets/image/L_image.png'),
                ),
              ),
            ),

            SizedBox(height: 5),

            Text(
              "Examora",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
            ),

            SizedBox(height: 0),

            Text(
              "Smart Exams. Better Results.",
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
