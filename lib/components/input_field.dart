import 'package:flutter/material.dart';

class myInput extends StatefulWidget {
  final controler;
  final String hint;


  const myInput({
    super.key,
    required this.controler,
    required this.hint,
  });

  @override
  State<myInput> createState() => _myInputState();
}

class _myInputState extends State<myInput> {

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controler,
      decoration: InputDecoration(
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: widget.hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
    );
  }
}


