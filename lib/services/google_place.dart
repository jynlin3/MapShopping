import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';

import '../models/place.dart';

class PlaceService {
  static const _secret_file_path = 'assets/config.json';

  static Future<String> _getAPIKey() async{
    // Load JSON file
    var jsonString = await rootBundle.loadString(_secret_file_path);
    var json = jsonDecode(jsonString);
    return json['google_api_key'];
  }

  static Future<List<Place>> getPlaces(double lat, double lng) async{
    var key = await _getAPIKey();
    var response = await get('https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&keyword=supermarket&distance=1500&rankby=distance&key=$key');
    var json = jsonDecode(response.body);
    var jsonResults = json['results'] as List;
    return jsonResults.map((place) => Place.fromJson(place)).toList();
  }
}