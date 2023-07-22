import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';

import '../components/button.dart';
import '../components/text_field.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({
    super.key,
    required this.onTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUp() async {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    if (passwordController.text != confirmPasswordController.text) {
      Navigator.pop(context);
      displayMessage("Passwords don't match");
    }

    try {

      // create user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      FirebaseFirestore.instance.collection("Users").doc(userCredential.user!.email).set({
        'email': emailController.text,
        'password': passwordController.text
      });

      if(context.mounted) {
        Navigator.pop(context);
      }
      
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      print(e.code);
      displayMessage(e.code);
    }
  }

  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //logo
                const Icon(
                  Icons.person,
                  size: 100,
                ),

                const SizedBox(height: 50),

                //Welcome back!
                Text(
                  translation(context).createAnAccount,
                ),

                const SizedBox(height: 25),

                //email textfield
                MyTextField(
                  controller: emailController,
                  hintText: translation(context).email,
                  obscureText: false,
                ),

                const SizedBox(height: 15),

                //password textfield
                MyTextField(
                  controller: passwordController,
                  hintText: translation(context).passWord,
                  obscureText: true,
                ),

                const SizedBox(height: 15),

                //confirm password textfield
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: translation(context).confirmPassword,
                  obscureText: true,
                ),

                const SizedBox(height: 15),

                //Sign in button
                MyButton(
                  onTap: signUp,
                  text: translation(context).signUp,
                ),

                const SizedBox(height: 15),

                // go to register page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(translation(context).alreadyAmember),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        translation(context).loginNow,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
