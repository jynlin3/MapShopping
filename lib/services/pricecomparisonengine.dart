import 'dart:convert';

import 'package:http/http.dart';

import '../models/product.dart';

class PriceComparisonEngineCore {
  static const _api_base = 'us-central1-mapshopping.cloudfunctions.net';

  static Future<dynamic> _getRecommendations(
      String searchTerm, String userDetail) async {
    // construct a Uri with query parameters
    final queryParameters = {'q': searchTerm, 'user_detail': userDetail};
    final uri = Uri.https(_api_base, '/recommendations_http', queryParameters);

    var headers = {'Accept': 'application/json'};
    var response = await get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('[PriceComparisonEngineCore] Fail to get recommendations from API');
      return {};
    }
  }
}

class PriceComparisonEngineParser extends PriceComparisonEngineCore {
  static Future<List<Product>> fetch(
      String searchTerm, String userDetail, String itemId) async {
    List<Product> products = [];
    var jsonResponse = await PriceComparisonEngineCore._getRecommendations(
        searchTerm, userDetail);
    for (var product in jsonResponse['recommendations']) {
      products.add(Product(
          name: product['name'],
          price: product['price'] * 1.0,
          store: product['store'],
          imageURL: product['imageUrl'],
          brand: product['brand'],
          itemId: itemId));
    }
    return products;
  }
}
