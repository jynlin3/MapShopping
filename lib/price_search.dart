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
                      return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                                Image(
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topRight,
                                  image: index % 2 == 1 ?
                                  NetworkImage('https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg') :
                                  NetworkImage('https://goodeggs1.imgix.net/product_photos/ZrGjmxboSBGgkiDGz3R3_20161130-StJohns_LargeEggsDozen_MG_7969.jpg?w=840&h=525&fm=jpg&q=80&fit=crop'),
                              ),
                              Expanded(
                                  child:Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(this._products[index].name,
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)
                                      ),
                                      SizedBox(height: 4),
                                      Text(this._products[index].store,
                                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      SizedBox(height: 8),
                                      Text("\$ ${this._products[index].price}",
                                          style: const TextStyle(fontSize: 21, color: Colors.black, fontWeight: FontWeight.bold))
                                    ]
                                )),
                            ],
                          ),
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