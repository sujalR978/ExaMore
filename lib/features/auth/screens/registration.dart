import 'package:flutter/material.dart';
import 'package:prep_mate/features/auth/widgets/filedTitle.dart';

import 'package:prep_mate/features/auth/widgets/googleButton.dart';
import 'package:prep_mate/features/auth/widgets/mainTitle.dart';
import 'package:prep_mate/features/auth/widgets/subTitle.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cPassword = TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _cPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 30,
              left: 32,
              right: 32,
            ),
            child: Column(
              children: [
                Container(
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
                    padding: const EdgeInsets.only(top: 32, bottom: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              width: 1,
                              color: Color(0xffE2E8F0),
                            ),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Image.asset('assets/image/image.png'),
                          ),
                        ),

                        Maintitle(text: "Create your Examora"),
                        Maintitle(text: "account"),
                        Subtitle(
                          text:
                              "Start your journey toward better exam \n                       \t   results.",
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 23, bottom: 23),
                          child: SizedBox(
                            width: 292,
                            height: 46,
                            child: Googlebutton(),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 23,
                            right: 32,
                            left: 32,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Color(0xffCBC4D2),

                                  endIndent: 10,
                                ),
                              ),

                              Text(
                                "OR CONTINUE WITH",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff7A7582),
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Color(0xffCBC4D2),
                                  indent: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Filedtitle(text: "Full Name")],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
