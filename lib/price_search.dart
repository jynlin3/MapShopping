import 'package:flutter/material.dart';

class ScreenArguments {
  final String title;

  ScreenArguments(this.title);
}
class PriceSearch extends StatefulWidget {
  static const routeName = '/priceSearch';

  @override
  _PriceSearchState createState() => _PriceSearchState();
}
class _PriceSearchState extends State<PriceSearch> {

  @override
  Widget build(BuildContext context) {
    final ScreenArguments args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: SafeArea(child: Text('price search page'))
    );
  }
}