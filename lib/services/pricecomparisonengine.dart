import 'dart:convert';

import 'package:http/http.dart';

import '../models/product.dart';

class PriceComparisonEngineCore {
  static const _api_base = 'https://us-central1-mapshopping.cloudfunctions.net';

  static Future<dynamic> _getRecommendations(String searchTerm, String userDetail) async{
    print("[Jyn]" + userDetail);
    // userDetail = "";
    var url = '$_api_base/recommendations_http?q=$searchTerm&user_detail=$userDetail';
    var headers = {
      'Accept': 'application/json'
    };
    var response = await get(url, headers:headers);

    if (response.statusCode == 200){
      return json.decode(response.body);
    }
    else {
      print('[PriceComparisonEngineCore] Fail to get recommendations from API');
      return {};
    }
  }
}

class PriceComparisonEngineParser extends PriceComparisonEngineCore {

  static Future<List<Product>> fetch(String searchTerm, String userDetail) async {
    List<Product> products = [];
    var jsonResponse = await PriceComparisonEngineCore._getRecommendations(searchTerm, userDetail);
    for (var product in jsonResponse['recommendations']){
      products.add(Product(
        product['name'],
        product['price'] * 1.0,
        product['store'],
        product['imageUrl'],
        product['brand'],
        ""
      ));
    }
    return products;
  }
}