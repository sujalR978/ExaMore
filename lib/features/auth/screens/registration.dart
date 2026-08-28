import 'package:flutter/material.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            child: Container(
              width: 358,
              
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 4),
                    blurRadius: 12,
                    color: Color(0xFF4C1D95).withValues(alpha: 0.04),
                  ),
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 1, color: Color(0xffE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 32,bottom: 32),
                child: Column(children: [
                            
                ],
                            ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
