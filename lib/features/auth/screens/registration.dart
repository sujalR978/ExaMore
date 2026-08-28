import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/widgets/button.dart';
import 'package:prep_mate/features/Auth/widgets/filedTitle.dart';
import 'package:prep_mate/features/Auth/widgets/googleButton.dart';
import 'package:prep_mate/features/Auth/widgets/inputField.dart';
import 'package:prep_mate/features/Auth/widgets/mainTitle.dart';
import 'package:prep_mate/features/Auth/widgets/subTitle.dart';
import 'package:prep_mate/features/Auth/widgets/textButton.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  bool _regis = false;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _cPassword.dispose();
    super.dispose();
  }

  Future<void> _registor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _regis = true;
    });

    try {} catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _regis = false;
        });
      }
    }
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

                          child: SizedBox(
                            width: double.infinity,

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Filedtitle(text: "Full Name"),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Inputfield(
                                      controller: _name,
                                      hintText: "John Doe",
                                      icon: Icons.person,
                                      isPassword: false,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return "Full name is required";
                                        }

                                        if (value.trim().length < 3) {
                                          return "Enter a valid name";
                                        }

                                        return null;
                                      },
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Filedtitle(text: "Email Address"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Inputfield(
                                      controller: _email,
                                      hintText: "student@university.edu",
                                      icon: Icons.email,
                                      isPassword: false,

                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return "Email is required";
                                        }

                                        final emailRegex = RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        );

                                        if (!emailRegex.hasMatch(
                                          value.trim(),
                                        )) {
                                          return "Enter a valid email";
                                        }

                                        return null;
                                      },
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Filedtitle(text: "Password"),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Inputfield(
                                      controller: _password,
                                      hintText: "••••••••",
                                      icon: Icons.lock,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Password is required";
                                        }

                                        if (value.length < 6) {
                                          return "Password must be at least 6 characters";
                                        }

                                        return null;
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Filedtitle(text: "Confirm Password"),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Inputfield(
                                      controller: _password,
                                      hintText: "••••••••",
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Confirm Password is required";
                                        }

                                        if (value != _password.text) {
                                          return "Passwords do not match";
                                        }

                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    height: 55,
                                    width: 308,
                                    child: Button(
                                      text: _regis
                                          ? "createing..."
                                          : "Create Account",
                                      icon: Icons.arrow_forward,
                                      onPressed: () {
                                        if (!_regis) _registor();
                                      },
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Subtitle(
                                        text: "Already have an account? ",
                                      ),
                                      Textbutton(
                                        text: "Login",
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => Login(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
