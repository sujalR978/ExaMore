import 'package:flutter/material.dart';
import 'package:prep_mate/features/auth/screens/forgetPassword.dart';
import 'package:prep_mate/features/auth/screens/registration.dart';
import 'package:prep_mate/features/auth/widgets/button.dart';
import 'package:prep_mate/features/auth/widgets/filedTitle.dart';
import 'package:prep_mate/features/auth/widgets/googleButton.dart';
import 'package:prep_mate/features/auth/widgets/inputField.dart';
import 'package:prep_mate/features/auth/widgets/mainTitle.dart';
import 'package:prep_mate/features/auth/widgets/subTitle.dart';
import 'package:prep_mate/features/auth/widgets/textButton.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLogin = false;

  @override
  void dispose() {
    // TODO: implement dispose
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  //Login handel

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLogin = true;
    });

    try {} catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLogin = false;
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
                      radius: 54,
                      backgroundImage: AssetImage('assets/image/L_image.png'),
                    ),
                  ),
                ),

                SizedBox(height: 5),

                Maintitle(text: "ExaMora"),

                SizedBox(height: 0),

                Subtitle(text: "Smart Exams. Better Results."),

                SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.rectangle,
                    border: Border.all(width: 1, color: Color(0xffE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  width: 358,
                  padding: EdgeInsets.only(
                    top: 24,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 46, width: 308, child: Googlebutton()),

                      Padding(
                        padding: const EdgeInsets.only(top: 23, bottom: 23),
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
                              "OR LOG IN WITH EMAIL",
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
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Filedtitle(text: "Email Address"),

                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  bottom: 8,
                                ),
                                child: Inputfield(
                                  controller: _email,
                                  hintText: "student@university.edu",
                                  icon: Icons.email,
                                  isPassword: false,

                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Email is required";
                                    }

                                    final emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );

                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return "Enter a valid email";
                                    }

                                    return null;
                                  },
                                ),
                              ),

                              Container(
                                child: Row(
                                  children: [
                                    Filedtitle(text: "Password"),

                                    SizedBox(width: 153),
                                    Textbutton(
                                      text: "Forgot Password?",
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
                              SizedBox(
                                height: 55,
                                width: 308,
                                child: Button(
                                  text: _isLogin ? "Logging in..." : "Login",
                                  icon: Icons.arrow_forward,
                                  onPressed: () {
                                    if (!_isLogin) login();
                                  },
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Subtitle(text: "Don't have an account?"),
                                  Textbutton(
                                    text: "Register",
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Registration(),
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
                    ],
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
