import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';

import '../models/place.dart';

class GoogleMapsService {
  static const _secret_file_path = 'assets/config.json';
  static const _url_base = 'https://maps.googleapis.com/maps/api';

  static Future<String> _getAPIKey() async{
    // Load JSON file
    var jsonString = await rootBundle.loadString(_secret_file_path);
    var json = jsonDecode(jsonString);
    return json['google_api_key'];
  }

  // Defines the distance (in meters)
  static Future<List<Place>> getPlaces(double lat, double lng, String keyword, int distance) async{
    var key = await _getAPIKey();
    var response = await get('$_url_base/place/nearbysearch/json?location=$lat,$lng&keyword=$keyword&distance=$distance&rankby=distance&key=$key');
    var json = jsonDecode(response.body);
    var jsonResults = json['results'] as List;
    return jsonResults.map((place) => Place.fromJson(place)).toList();
  }

  static Future<String> getDistance(double oriLat, double oriLng, double desLat, double desLng) async{
    if (oriLat == null || oriLng == null || desLng == null || desLat == null) {
      return "";
    }

    var key = await _getAPIKey();
    var response = await get('$_url_base/distancematrix/json?origins=$oriLat,$oriLng&destinations=$desLat,$desLng&key=$key');
    var json = jsonDecode(response.body);
    try {
      return json['rows'][0]['elements'][0]['distance']['text'];
    } catch(e) {
      print("[Google Maps] Fail to get distance");
      print(e);
    }
    return "";
  }
}