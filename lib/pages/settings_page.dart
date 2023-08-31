import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map/classes/language.dart';
import 'package:map/classes/language_constants.dart';
import 'package:map/components/text_box.dart';
import 'package:map/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  //user
  final currentUser = FirebaseAuth.instance.currentUser!;
  // every user
  final usersCollection = FirebaseFirestore.instance.collection("Users");

  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Edit $field',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          //Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              translation(context).cancel,
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // save button
          TextButton(
            onPressed: () => Navigator.of(context).pop(newValue),
            child: Text(
              translation(context).save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // update in firestore
    if (newValue.trim().isNotEmpty) {
      await usersCollection.doc(currentUser.email).update({field: newValue});
      if (newValue.contains("@")) {
        currentUser.updateEmail(newValue);
      } else {
        currentUser.updatePassword(newValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUser.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return ListView(
              children: [
                const SizedBox(
                  height: 20,
                ),
                // profile icon
                Image.asset(
                  'images/Aspire+ZayedUni.jpg',
                  width: 200,
                  height: 200,
                ),

                // user email
                const SizedBox(
                  height: 5,
                ),
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black),
                ),

                const SizedBox(
                  height: 50,
                ),

                // user email field
                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: Text(
                    translation(context).myDetails,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                MyTextBox(
                  text: userData['email'],
                  sectionName: translation(context).email,
                  onPressed: () => editField('email'),
                ),

                // user password
                const SizedBox(
                  height: 10,
                ),

                MyTextBox(
                  text: userData['password'],
                  sectionName: translation(context).passWord,
                  onPressed: () => editField('password'),
                ),

                const SizedBox(
                  height: 10,
                ),

                Container(
                  child: Center(
                    child: DropdownButton<Language>(
                      hint: Text(translation(context).changeLanguage),
                      items: Language.languageList()
                          .map<DropdownMenuItem<Language>>(
                            (e) => DropdownMenuItem<Language>(
                              value: e,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  Text(e.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (Language? language) async {
                        //do something
                        if (language != null) {
                          Locale _locale =
                              await setLocale(language.languageCode);
                          MyApp.setLocale(context, _locale);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                FloatingActionButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  backgroundColor: Colors.green.shade500,
                  child: const Icon(Icons.logout_outlined),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error ${snapshot.error}'),
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
