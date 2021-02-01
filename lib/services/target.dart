import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';

import 'opendatasoft.dart';
import '../models/product.dart';
import '../models/store.dart';


class TargetCore {
  Map<String, String> _headers;
  static const _secret_file_path = 'assets/config.json';
  static const _url_base = 'https://target1.p.rapidapi.com';

  Future<void> _getAPIKey() async{
    // Load JSON file
    var jsonString = await rootBundle.loadString(_secret_file_path);
    var json = jsonDecode(jsonString);
    _headers = {
      'x-rapidapi-key': json['target_api_key'],
      'x-rapidapi-host': 'target1.p.rapidapi.com'
    };
  }

  Future<dynamic> _getStores(String zipCode) async{
    var url = '${_url_base}/stores/list?zipcode=${zipCode}';
    var response = await get(url, headers: _headers);

    if(response.statusCode == 200){
      return json.decode(response.body);
    }else{
      print('[Target] Fail to get stores from API');
      print(response);
      return {};
    }
  }

  Future<dynamic> _getProducts(String searchTerm, String locationId, {pageNum=1}) async{
    var url = '${_url_base}/products/list?storeId=${locationId}&pageSize=20&pageNumber=${pageNum}&sortBy=relavance&searchTerm=${searchTerm}';
    var response = await get(url, headers: _headers);
    if(response.statusCode == 200){
      return jsonDecode(response.body);
    }
    else{
      print('[Target] Fail to get products from API');
      print(response.statusCode);
      return {};
    }
  }
}

class TargetParser extends TargetCore {

  Future<List<Store>> collectStores(double lat, double long) async{
    var zipCode = await OpenDataSoftParser.findZipCode(lat, long);

    var jsonResponse = await _getStores(zipCode);

    List<Store> stores = [];
    try{
      for (var store in jsonResponse[0]['locations']){
        if(store.containsKey('location_id')){
          stores.add(Store(
              'Target',
              store['location_id'].toString()
          ));
        }
      }
    }
    catch(e){
      print('[Target] Fail to parse location id');
      print(e);
    }

    return stores.isNotEmpty ? stores : [Store('Target', '3286')];
  }

  String _findName(dynamic jsonProduct){
    return jsonProduct.containsKey('title')==null ? '' : jsonProduct['title'];
  }

  double _findPrice(dynamic jsonProduct){
    try{
      if (jsonProduct['price'].containsKey('current_retail_min'))
        return jsonProduct['price']['current_retail_min'];
      return double.parse(jsonProduct['price']['formatted_current_price'].split('\$')[1]);
    }
    catch(e){
      var name = _findName(jsonProduct);
      print('[Target] Fail to find price of ${name}');
      print(e);
    }
    return 0;
  }

  String _findImageURL(dynamic jsonProduct){
    try{
      return jsonProduct['images']['primaryUri'];
    }
    catch(e){
      var name = _findName(jsonProduct);
      print('[Target] Fail to find price of ${name}');
      print(e);
    }
    return 'https://www.stma.org/wp-content/uploads/2017/10/no-image-icon.png';
  }

  Future<List<Product>> _collectProducts(String searchTerm, String locationId) async{
    List<Product> products = [];
    var totalPage = 0;
    var curPage = 1;
    do{
      var jsonResponse = await _getProducts(searchTerm, locationId);

      if(jsonResponse.containsKey('totalPages')){
        totalPage = int.parse(jsonResponse['totalPages']);
      }

      if(jsonResponse.containsKey('products')){
        for(var product in jsonResponse['products']){
          products.add(Product(
              _findName(product),
              _findPrice(product),
              'Target',
              _findImageURL(product),
              ''));
        }
      }

      curPage+=1;
    }while(curPage <= totalPage);

    return products;
  }

  Future<List<Product>> fetch(String searchTerm) async {
    await _getAPIKey();
    var stores = await collectStores(47.690952, -122.301245);

    if (stores.isEmpty){
      return [];
    }

    return await _collectProducts(searchTerm, stores[0].locationId);
  }
}