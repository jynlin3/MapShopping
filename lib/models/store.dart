class Store{
  String name = "";
  String locationId = "";
  double latitude = 180;
  double longitude = 90;
  String distance = "";

  Store(String name, String locationId, double latitude, double longitude, String distance){
    this.name = name;
    this.locationId = locationId;
    this.latitude = latitude;
    this.longitude = longitude;
    this.distance = distance;
  }
}