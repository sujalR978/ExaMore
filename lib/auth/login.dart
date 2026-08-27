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

                SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.rectangle,
                    border: Border.all(width: 1, color: Color(0xffE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: 426.36,
                  width: 358,
                  padding: EdgeInsets.only(
                    top: 24,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 46,
                        width: 308,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              width: 1,
                              color: Color(0xffCBC4D2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                        ),
                      ),

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
                                color: Color(0xff494550),
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

                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email Address",
                              style: TextStyle(
                                fontWeight: FontWeight(600),
                                color: Color(0xff0B1C30),
                                fontSize: 14,
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 8,
                              ),
                              child: SizedBox(
                                height: 40.59,
                                width: 308,

                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "student@university.edu",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,

                                    prefixIcon: Icon(Icons.email),
                                    fillColor: Color(0xffF8FAFC),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
