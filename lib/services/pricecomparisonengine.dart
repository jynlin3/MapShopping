import 'dart:convert';

import 'package:http/http.dart';

import '../models/product.dart';

class PriceComparisonEngineCore {
  static const _api_base = 'https://price-comparison-engine.herokuapp.com';

  static Future<dynamic> _getRecommendations(String searchTerm, String userDetail) async{
    searchTerm = "soda";
    userDetail = "coca-cola";
    var url = '$_api_base/recommendations?q=$searchTerm&user_detail=$userDetail';
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

  static Future<List<Product>> fetch(String searchTerm) async {
    List<Product> products = [];
    var jsonResponse = await PriceComparisonEngineCore._getRecommendations(searchTerm, '');
    for (var product in jsonResponse['recommendations']){
      products.add(Product(
        product['name'],
        product['price'],
        product['store'],
        product['imageUrl'],
        product['brand'],
        ""
      ));
    }
    return products;
  }
}