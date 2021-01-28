import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

import 'models/product.dart';
import 'services/kroger.dart';
import 'services/safeway_parser.dart';
import 'services/target.dart';

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
  WebViewPlusController _controller;

  List<Product> _products = [];
  String _title;

  bool _isKrogerFetched = false;
  bool _isTargetFetched = false;

  @override
  Widget build(BuildContext context) {
    final ScreenArguments args = ModalRoute.of(context).settings.arguments;
    _title = args.title;

    executeAfterBuild();

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Column(
        children: <Widget>[
          Visibility(
              visible: false,
              maintainState: true,
              child: SizedBox(
                  height: 1,
                  child: WebViewPlus(
                    initialUrl: SafewayParser.getURL(args.title),
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (controller){
                      this._controller = controller;
                    },
                    onPageFinished: (url){
                      print('Page loaded: $url');
                      fetchSafewayData();
                    },
              ))),
          Text('price search page'),
          Expanded(
              child: ListView.builder(
                    itemCount: this._products.length,
                    itemBuilder: (BuildContext context, int index){
                      return Container(
                          key: Key(this._products[index].name),
                          child: Card(
                              child: ListTile(
                                title: Text(this._products[index].name),
                              ))
                      );
                    }
          )),
        ],
      )
    );
  }

  void fetchSafewayData() async {
    String docu = await this._controller.evaluateJavascript('document.documentElement.innerHTML');
    var html = json.decode(docu);
    var dom = parse(html);

    var products = SafewayParser.collectProducts(dom);
    for(var p in products){
      print('${p.name}\t ${p.price} from ${p.store}\t${p.imageURL}');
    }

    setState(() {
      _products.addAll(products);
    });
  }

  Future<void> fetchKrogerData() async {
    var kroger = KrogerParser();
    var products = await kroger.fetch(_title);
    for (var p in products) {
      print('${p.name}\t ${p.price} from ${p.store}\t${p.imageURL}');
    }
    setState(() {
      _products.addAll(products);
    });
  }

  Future<void> fetchTargetData() async {
    var target = TargetParser();
    var products = await target.fetch(_title);
    for (var p in products){
      print('${p.name}\t ${p.price} from ${p.store}\t${p.imageURL}');
    }
    setState(() {
      _products.addAll(products);
    });
  }

  void executeAfterBuild() {
    if (!_isKrogerFetched) {
      _isKrogerFetched = true;
      fetchKrogerData();
    }
    if (! _isTargetFetched) {
      _isTargetFetched = true;
      fetchTargetData();
    }
  }


}