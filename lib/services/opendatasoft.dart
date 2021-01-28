import 'dart:convert';

import 'package:http/http.dart';

class OpenDataSoftCore{
  static const _api_base = 'https://public.opendatasoft.com';

  static Future<dynamic> _getZipCodes(double lat, double long, {rad= 1000}) async{
    var url = '${_api_base}/api/records/1.0/search/?dataset=us-zip-code-latitude-and-longitude&q=&facet=state&facet=timezone&facet=dst&geofilter.distance=${lat}%2C${long}%2C${rad}';
    var headers = {
      'Accept': 'application/json'
    };
    var response = await get(url, headers: headers);

    if (response.statusCode == 200){
      return json.decode(response.body);
    }
    else {
      print('[OpenDataSoft] Fail to get zip code from API');
      return {};
    }
  }
}

class OpenDataSoftParser extends OpenDataSoftCore{
  static Future<String> findZipCode(double lat, double long) async{
    var jsonResponse = await OpenDataSoftCore._getZipCodes(lat, long);

    try {
      return jsonResponse['records'][0]['fields']['zip'];
    }
    catch(e){
      print('[OpenDataSoft] Fail to parse zip code');
      print(e);
    }
    return '98115';
  }
}