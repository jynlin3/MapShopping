import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_geofence/Geolocation.dart';
import 'package:flutter_geofence/geofence.dart';

import 'database_helper.dart';
import 'price_search.dart';
import 'services/googlemaps.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => MyHomePage(title: 'Flutter Demo Home Page'),
        PriceSearch.routeName: (context) => PriceSearch(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  late PageController _pageController;

  late GoogleMapController _mapController;
  final LatLng _center = const LatLng(45.521563, -122.677433);

  Geolocator _geolocator = Geolocator();
  Set<Marker> _markers = {};

  List<Item> _items = [];
  String _input = "";
  final _dbHelper = DatabaseHelper.instance;

  // final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    this._pageController = PageController();
    setupList();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Map Shopping'),
      ),
      body: PageView(
        children: <Widget>[
          // home page
          ListView.builder(
              // controller: _scrollController,
              // reverse: true,
              itemCount: this._items.length,
              itemBuilder: (BuildContext context, int index){
                return Container(
                  key: Key(this._items[index].title),
                  child: Card(
                      child: ListTile(
                        title: Text(this._items[index].title),
                        trailing: Row(
                            children: <Widget>[
                              IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: () {Navigator.pushNamed(
                                    context,
                                    PriceSearch.routeName,
                                    arguments: ScreenArguments(this._items[index].title),
                                  );}
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {onPressDelete(this._items[index]);},
                              ),
                            ],
                            mainAxisSize:  MainAxisSize.min
                        ),
                        onTap: (){
                          _input = this._items[index].title;
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Edit Shopping Item'),
                                  content: TextField(
                                    controller: TextEditingController(text: _input),
                                    onChanged: (String value){_input = value;},
                                  ),
                                  actions: <Widget>[
                                    FlatButton(
                                        onPressed: (){onPressEdit(this._items[index]);},
                                        child: Text('Edit')
                                    )
                                  ],
                                );
                              });
                        },
                      ))
                );
              }
            ),
          // settings page
          Center(child: Text('Settings')),
          // navigation map page
          GoogleMap(
            onMapCreated: (controller){
              this._mapController = controller;
              _checkLocationPermission().then((status){
                debugPrint('----- Geolocation Status: ${status}');
              });
              _animateToUser();
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            myLocationEnabled: true
          )
        ],
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            this._currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
              backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.navigation),
              label: 'Navigation Map',
              backgroundColor: Colors.blue
          ),
        ],
        onTap: (index) {
          this._pageController.animateToPage(index,
              duration: Duration(milliseconds: 1),
              curve: Curves.easeIn);
        }
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          _input = '';
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add Shopping Item'),
                content: TextField(
                  onChanged: (String value){
                    _input = value;
                  },
                ),
                actions: <Widget>[
                  FlatButton(
                      onPressed: onPressAdd,
                      child: Text('Add')
                  )
                ],
              );
            });
        },
        child: Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Future<GeolocationStatus> _checkLocationPermission() async {
    GeolocationStatus geolocationStatus = await Geolocator().checkGeolocationPermissionStatus();
    return geolocationStatus;
  }

  _animateToUser() async {
    var currentPos;
    try {
      currentPos = await this._geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      debugPrint('----- userLocation: ${currentPos}');
    } catch(e) {
      print(e);
      return;
    }

    this._mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(currentPos.latitude, currentPos.longitude),
      zoom: 13.0,
    )));

    getMarkers(currentPos.latitude, currentPos.longitude);
  }

  void setupList() async{
    var items = await this._dbHelper.getAllItems();
    setState(() {
      _items = items;
    });
  }

  void onPressDelete(Item item) async{
    var id = await this._dbHelper.updateItem(Item(
        id: item.id,
        title: item.title,
        isDeleted: true
    ));
    print('update row id: $id');

    this._dbHelper.getAllItems().then((items){
      setState(() {
        _items = items;
      });
    });
  }

  void onPressAdd() async{
    if(this._input.isEmpty)
      return;

    final id = await this._dbHelper.insertItem(Item.random(_input, false));
    print('inserted row id: $id');

    this._dbHelper.getAllItems().then((items){
      setState(() {
        _items = items;
      });
    });

    Navigator.of(context, rootNavigator: true).pop();
    // this._scrollController.animateTo(
    //     _scrollController.position.minScrollExtent,
    //     duration: Duration(milliseconds: 500),
    //     curve: Curves.fastOutSlowIn
    // );
  }

  void onPressEdit(Item item) async{
    var id = await this._dbHelper.updateItem(Item(
        id: item.id,
        title: this._input,
        isDeleted: false
    ));
    print('update row id: $id');

    this._dbHelper.getAllItems().then((items){
      setState(() {
        _items = items;
      });
    });

    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> getMarkers(double lat, double lng) async{
    var places = await GoogleMapsService.getPlaces(lat, lng);
    for (var p in places) {
      print('${p.name}\t ${p.rating}(${p.userRatingCount}) ${p.openStatus} ${p.latitude} ${p.longitude} ');
    }

    var markers = <Marker>[];
    places.forEach((place){
      Marker marker = Marker(
        markerId: MarkerId(place.placeId),
        draggable: false,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: place.name),
        position: LatLng(place.latitude, place.longitude)
      );

      markers.add(marker);
    });

    setState((){
      this._markers.addAll(markers);
    });
  }

  Future<void> initPlatformState() async {
    Geofence.initialize();
    Geofence.startListening(GeolocationEvent.entry, (evt) {
      scheduleNotification("Entry of a georegion", "Welcome to: ${evt.id}");
    });
    Geofence.startListening(GeolocationEvent.exit, (evt) {
      scheduleNotification("Exit of a georegion", "Byebye to: ${evt.id}");
    });
  }

  void scheduleNotification(String title, String subtitle) {
    print("scheduling one with $title and $subtitle");
    //TODO: show notification on phone
  }
}
