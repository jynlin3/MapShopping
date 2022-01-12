import '../database_helper.dart';

class Place{
  final String name;
  final double rating;
  final int userRatingCount;
  final String openStatus;
  final double latitude;
  final double longitude;
  final String placeId;

  Place({required this.name, required this.rating, required this.userRatingCount, required this.openStatus, required this.latitude, required this.longitude, required this.placeId});

  Place.fromJson(Map<dynamic, dynamic> parsedJson)
      :name = parsedJson['name'],
        rating = (parsedJson['rating']!=null) ? parsedJson['rating'].toDouble() : null,
        userRatingCount = parsedJson['user_ratings_total'],
        openStatus = (parsedJson['opening_hours']!=null && parsedJson['opening_hours']['open_now'] != null) ? ((parsedJson['opening_hours']['open_now']) ? "Open":"Closed") : "Unknown",
        latitude = parsedJson['geometry']['location']['lat'].toDouble(),
        longitude = parsedJson['geometry']['location']['lng'].toDouble(),
        placeId = parsedJson['place_id'];

  // Convert a Place to a Map.
  Map<String, dynamic> toMap(){
    return {
      columnId: null,
      columnName: this.name,
      columnLat: this.latitude,
      columnLong: this.longitude,
      columnIsDeleted: 0
    };
  }

  // Convert a Map into a Place.
  Place.fromDB(Map<String, dynamic> map):
      name = map[columnName],
      rating = 0,
      userRatingCount = 0,
      openStatus = '',
      latitude = map[columnLat],
      longitude = map[columnLong],
      placeId = "${map[columnName]} ${map[columnId]}";
}