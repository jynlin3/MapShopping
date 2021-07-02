import 'dart:convert';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

import 'database_helper.dart';
import 'models/product.dart';
import 'services/googlemaps.dart';
import 'services/kroger.dart';
import 'services/pricecomparisonengine.dart';
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
  late WebViewPlusController _controller;

  List<Product> _products = [];
  // late List<Product> _products;
  String _title = "";

  bool _isKrogerFetched = false;
  bool _isTargetFetched = false;
  bool _isRecommendationFetched = false;

  // Stopwatch stopWatch = Stopwatch();

  final _dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    final ScreenArguments args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
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
                    // onPageStarted: (url){
                    //   stopWatch.start();
                    // },
                    onPageFinished: (url){
                      print('Page loaded: $url');
                      // fetchSafewayData();
                    },
              ))),
          (_products == null)
              ? Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                        itemCount: this._products.length,
                        itemBuilder: (BuildContext context, int index){
                          return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                    FadeInImage.memoryNetwork(
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.centerLeft,
                                      image: this._products[index].imageURL,
                                      placeholder: kTransparentImage,
                                  ),
                                  Expanded(
                                      child:Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(this._products[index].name,
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)
                                          ),
                                          SizedBox(height: 4),
                                          Text("${this._products[index].store}  ${this._products[index].distance}",
                                              style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                          SizedBox(height: 8),
                                          Text("\$ ${this._products[index].price}",
                                              style: const TextStyle(fontSize: 21, color: Colors.black, fontWeight: FontWeight.bold)),
                                          IconButton(
                                              icon: this._products[index].isDeleted ? Icon(Icons.bookmark_border) : Icon(Icons.bookmark),
                                              onPressed: () {
                                                if(this._products[index].isDeleted)
                                                  onPressAdd(index);
                                                else
                                                  onPressDelete(index);
                                              }
                                          ),
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

  // void fetchSafewayData() async {
  //   String docu = await this._controller.evaluateJavascript('document.documentElement.innerHTML');
  //   var html = json.decode(docu);
  //   var dom = parse(html);
  //
  //   var products = SafewayParser.collectProducts(dom);
  //
  //   print('safeway parser executed in ${stopWatch.elapsed}');
  //
  //   var lat = 47.690952;
  //   var lng = -122.301245;
  //   var places = await GoogleMapsService.getPlaces(lat, lng);
  //   var dist = '';
  //   for(var p in places){
  //     if(p.name == 'Safeway'){
  //        dist = await GoogleMapsService.getDistance(lat, lng, p.latitude, p.longitude);
  //        break;
  //     }
  //   }
  //
  //   if(dist.isNotEmpty){
  //     for(var p in products){
  //       p.distance = dist;
  //       print('${p.name}\t ${p.price} from ${p.store}\t${p.imageURL}\t${p.distance}');
  //     }
  //   }
  //
  //   setState(() {
  //     _products.addAll(products);
  //     _products.sort((a, b) => a.price.compareTo(b.price));
  //   });
  // }

  // Future<void> fetchKrogerData() async {
  //   var kroger = KrogerParser();
  //   var products = await kroger.fetch(_title);
  //   for (var p in products) {
  //     print('${p.name}\t ${p.price} from ${p.store}\t${p.distance}');
  //   }
  //   setState(() {
  //     _products.addAll(products);
  //     _products.sort((a, b) => a.price.compareTo(b.price));
  //   });
  // }
  //
  // Future<void> fetchTargetData() async {
  //   var target = TargetParser();
  //   var products = await target.fetch(_title);
  //   for (var p in products){
  //     print('${p.name}\t ${p.price} from ${p.store}\t${p.distance}');
  //   }
  //   setState(() {
  //     _products.addAll(products);
  //     _products.sort((a, b) => a.price.compareTo(b.price));
  //   });
  // }
  Future<void> fetchRecommendations() async {
    var saved_products = await this._dbHelper.getAllProducts();
    var user_detail_list = saved_products.map((p) => p.name);
    var recommendations = await PriceComparisonEngineParser.fetch(_title, user_detail_list.join(" "));
    for (var r in recommendations) {
      for (var p in saved_products) {
        if (r.name == p.name)
          r.isDeleted = false;
      }
    }

    setState(() {
      _products = recommendations;
    });
  }

  void executeAfterBuild() {
    // if (!_isKrogerFetched) {
    //   _isKrogerFetched = true;
    //   fetchKrogerData();
    // }
    // if (! _isTargetFetched) {
    //   _isTargetFetched = true;
    //   fetchTargetData();
    // }
    if (!_isRecommendationFetched) {
      _isRecommendationFetched = true;
      fetchRecommendations();
    }
  }

  void onPressAdd(int index){
    setState(() {
      _products[index].isDeleted = false;
    });
    this._dbHelper.insertProduct(_products[index]);
  }

  void onPressDelete(int index) async {
    await this._dbHelper.deleteProduct(_products[index].name);
    this._dbHelper.getAllProducts().then((items){
      print(items);
    });

    setState(() {
      _products[index].isDeleted = true;
    });
  }


}