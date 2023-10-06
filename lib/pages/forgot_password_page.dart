import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';
import 'package:map/components/text_field.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailController = TextEditingController();

  //final usersCollection = FirebaseFirestore.instance.collection("Users");

  //final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void dispose() {
    // TODO: implement dispose
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.message.toString()),
            );
          });
    }
  }

    String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
  }

  Color _changeColorTheme700() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return Colors.red.shade700;
    } else if (currentLanguage == 'fr') {
      return Colors.blue.shade700;
    } else if (currentLanguage == 'ar') {
      return Colors.green.shade700;
    }

    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              translation(context).emailReset,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ),

          const SizedBox(height: 50),

          //email textfield
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: MyTextField(
              controller: emailController,
              hintText: translation(context).email,
              obscureText: false,
              suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.outgoing_mail)),
              context: context,
            ),
          ),

          const SizedBox(height: 50),

          MaterialButton(
            onPressed: passwordReset,
            color: _changeColorTheme700(),
            minWidth: 20,
            height: 70,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            child: Text(
              translation(context).resetPassword,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
