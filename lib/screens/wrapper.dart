import 'package:flutter/material.dart';

import 'authenticate/authenticate.dart';
import 'home/home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return either Home or Authenticate widget
    // return MyHomePage(title: 'Flutter Demo Home Page');
    return Authenticate();
  }
}
