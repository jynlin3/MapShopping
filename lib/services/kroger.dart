import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';

import 'googlemaps.dart';
import '../models/product.dart';
import '../models/store.dart';


class KrogerCore {
  String _access_token;

  static const _secret_file_path = 'assets/config.json';
  static const String _api_base = 'https://api.kroger.com';

  Future<String> _getCredentials() async {
    var jsonString = await rootBundle.loadString(_secret_file_path);
    Map<String, dynamic> json = jsonDecode(jsonString);
    String clientID = json['kroger_client_id'];
    String clientSecret = json['kroger_client_secret'];
    var encoded = utf8.encode('${clientID}:${clientSecret}');
    return base64Encode(encoded);
  }

  Future<void> _getAccessToken(String credentials) async {
    Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ${credentials}'
    };
    String payload = 'grant_type=client_credentials&scope=product.compact';
    final response = await post(
        '${_api_base}/v1/connect/oauth2/token', headers: headers,
        body: payload);
    final responseJson = json.decode(response.body);
    this._access_token = responseJson['access_token'];
  }

  Future<dynamic> _getLocations(double lat, double long, {radius: 1}) async{
    String url = '${_api_base}/v1/locations?filter.latLong.near=${lat},${long}&filter.radiusInMiles=${radius}';
    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_access_token}'
    };
    Response response = await get(url, headers: headers);
    if(response.statusCode == 401){
      await _getAccessToken(await _getCredentials());
      return _getLocations(lat, long, radius: radius);
    }

    if(response.statusCode == 200)
      return json.decode(response.body);
    else {
      print('[Kroger] Fail to get locations!');
      return {};
    }
  }

  Future<dynamic> _getProducts(String searchTerm, String locationId) async{
    if (searchTerm.length < 2)
      return {};

    var url = '${_api_base}/v1/products?filter.term=${searchTerm}&filter.locationId=${locationId}&filter.limit=50';
    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_access_token}'
    };
    Response response = await get(url, headers: headers);
    if(response.statusCode == 401){
      await _getAccessToken(await _getCredentials());
      return _getProducts(searchTerm, locationId);
    }

    if(response.statusCode == 200)
      return json.decode(response.body);
    else{
      print('[Kroger] Failed to get products!');
      return {};
    }
  }
}

class KrogerParser extends KrogerCore {
  Future<List<Store>> collectStores(double lat, double long) async{
    var jsonResponse = await _getLocations(lat, long);
    if (!jsonResponse.containsKey('data'))
      return [];

    var stores = Map<String, Store>();
    for (var store in jsonResponse['data']) {
      if (!store.containsKey('locationId') || !store.containsKey('name') || !store.containsKey('chain'))
        continue;
      if (stores.containsKey(store['chain']))
        continue;

      var storeLat = (store.containsKey('geolocation')) ? store['geolocation']['latitude'] : null;
      var storeLng = (store.containsKey('geolocation')) ? store['geolocation']['longitude'] : null;

      stores[store['chain']] = Store(
        store['name'],
        store['locationId'],
          storeLat,
          storeLng,
        await GoogleMapsService.getDistance(lat, long, storeLat, storeLng)
      );
    }
    return stores.values.toList();
  }

  String _findName(dynamic jsonItem){
    if (jsonItem.containsKey('description'))
      return jsonItem['description'];
    else
      return '';
  }

  double _findPrice(dynamic jsonItem){
    try {
      var priceMap = jsonItem['items'][0]['price'];
      if(priceMap.containsKey('promo') && priceMap['promo'] > 0)
        return priceMap['promo'] is int ? priceMap['promo'].toDouble() : priceMap['promo'];
      return priceMap['regular'] is int ? priceMap['regular'].toDouble() : priceMap['regular'];
    }
    catch(e){
      String name = _findName(jsonItem);
      print('[Kroger] Fail to find price for $name');
      print(e);
    }
    return 0.0;
  }

  String _findImageURL(dynamic jsonItem){
    if(jsonItem.containsKey('productId'))
      return 'https://www.kroger.com/product/images/large/front/${jsonItem['productId']}';
    else
      return 'https://www.stma.org/wp-content/uploads/2017/10/no-image-icon.png';
  }

  Future<List<Product>> _collectProducts(String searchTerm, List<Store> stores) async{
    List<Product> products = [];
    for(var store in stores){
      var jsonResponse = await _getProducts(searchTerm, store.locationId);
      if (jsonResponse['data'] == null)
        continue;

      for(var item in jsonResponse['data']){
        // filter products without price
        var price = _findPrice(item);
        if (price <= 0)
          continue;

        products.add(Product(
          _findName(item),
          price,
          store.name,
          _findImageURL(item),
          '',
          store.distance
        ));
      }
    }
    return products;
  }

  Future<List<Product>> fetch(String searchTerm) async{
    if (this._access_token == null) {
      await _getAccessToken(await _getCredentials());
    }
    var stores = await collectStores(47.69173809759271, -122.30139442037989);
    return _collectProducts(searchTerm, stores);
  }
}