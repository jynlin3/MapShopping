import 'package:html/parser.dart';

class Place{
  final String name;
  final double rating;
  final int userRatingCount;
  final String openStatus;
  final double latitude;
  final double longitude;
  final String placeId;

  Place({this.name, this.rating, this.userRatingCount, this.openStatus, this.latitude, this.longitude, this.placeId});

  Place.fromJson(Map<dynamic, dynamic> parsedJson)
      :name = parsedJson['name'],
        rating = (parsedJson['rating']!=null) ? parsedJson['rating'].toDouble() : null,
        userRatingCount = parsedJson['user_ratings_total'],
        openStatus = (parsedJson['opening_hours']!=null) ? ((parsedJson['opening_hours']['open_now']) ? "Open":"Closed") : "Unknown",
        latitude = parsedJson['geometry']['location']['lat'].toDouble(),
        longitude = parsedJson['geometry']['location']['lng'].toDouble(),
        placeId = parsedJson['place_id'];
}