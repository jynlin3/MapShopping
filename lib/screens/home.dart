import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofence/Geolocation.dart';
import 'package:flutter_geofence/geofence.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:transparent_image/transparent_image.dart';

import '../database_helper.dart';
import '../models/item.dart';
import '../models/product.dart';
import '../services/firestore.dart';
import '../services/googlemaps.dart';
import 'custom_icons_icons.dart';
import 'price_search.dart';


class MyHomePage extends StatefulWidget {
  final String uid;

  MyHomePage({Key? key, required this.uid}) : super(key: key);

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

  // final ScrollController _scrollController = ScrollController();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  List<Product> _products = [];
  int _week = 0;

  @override
  void initState() {
    super.initState();
    this._pageController = PageController();
    setupList();

    if ((defaultTargetPlatform == TargetPlatform.iOS) ||
        (defaultTargetPlatform == TargetPlatform.android)) {
      initGeofence();
      initLocalNotificationPlugin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Shopping'),
        actions: [
          IconButton(
            icon: const Icon(CustomIcons.next_week),
            tooltip: 'Next week',
            onPressed: () {
              setState(() {
                _week += 1;
              });
            },
          )
        ],
      ),
      body: PageView(
        children: <Widget>[
          // home page
          ListView.builder(
              // controller: _scrollController,
              // reverse: true,
              itemCount: this._items.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                    key: Key(this._items[index].title),
                    child: Card(
                        child: ListTile(
                      // Note: Disable checkbox for user testing.
                      // leading: Checkbox(
                      //     value: this._items[index].isChecked,
                      //     onChanged: (newValue) {
                      //       onClickCheckbox(this._items[index], newValue);
                      //     }),
                      title: Text(this._items[index].title,
                          style: TextStyle(
                              decoration: this._items[index].isChecked
                                  ? TextDecoration.lineThrough
                                  : null)),
                      trailing: Row(children: <Widget>[
                        IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () async {
                              String referenceId =
                                  this._items[index].referenceId ?? "";

                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PriceSearch(
                                          title: this._items[index].title,
                                          itemId: referenceId,
                                          uid: widget.uid,
                                          week: _week)));

                              // Refresh bookmark list.
                              setupList();
                            }),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            onPressDelete(this._items[index]);
                          },
                        ),
                      ], mainAxisSize: MainAxisSize.min),
                      onTap: () {
                        _input = this._items[index].title;
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Edit Shopping Item'),
                                content: TextField(
                                  controller:
                                      TextEditingController(text: _input),
                                  onChanged: (String value) {
                                    _input = value;
                                  },
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                      onPressed: () {
                                        onPressEdit(this._items[index]);
                                      },
                                      child: Text('Edit'))
                                ],
                              );
                            });
                      },
                    )));
              }),
          // bookmark page
          ListView.builder(
              itemCount: this._products.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      FadeInImage.memoryNetwork(
                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        image: this._products[index].imageURL,
                        placeholder: kTransparentImage,
                      ),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                            Text(this._products[index].name,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                                "${this._products[index].store}  ${this._products[index].distance}",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text("\$ ${this._products[index].price}",
                                style: const TextStyle(
                                    fontSize: 21,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ])),
                    ],
                  ),
                );
              }),
          // settings page
          Center(child: Text('Settings')),
          // navigation map page
          GoogleMap(
              onMapCreated: (controller) {
                this._mapController = controller;
                _checkLocationPermission().then((status) {
                  debugPrint('----- Geolocation Status: ${status}');
                });
                _animateToUser();
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: _markers,
              myLocationEnabled: true)
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
                backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.bookmarks),
                label: 'Bookmarks',
                backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
                backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.navigation),
                label: 'Navigation Map',
                backgroundColor: Colors.blue),
          ],
          onTap: (index) {
            this._pageController.animateToPage(index,
                duration: Duration(milliseconds: 1), curve: Curves.easeIn);
          }),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _input = '';
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Add Shopping Item'),
                        content: TextField(
                          onChanged: (String value) {
                            _input = value;
                          },
                        ),
                        actions: <Widget>[
                          TextButton(onPressed: onPressAdd, child: Text('Add'))
                        ],
                      );
                    });
              },
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Future<GeolocationStatus> _checkLocationPermission() async {
    GeolocationStatus geolocationStatus =
        await Geolocator().checkGeolocationPermissionStatus();
    return geolocationStatus;
  }

  _animateToUser() async {
    var currentPos;
    try {
      currentPos = await this
          ._geolocator
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      debugPrint('----- userLocation: ${currentPos}');
    } catch (e) {
      print(e);
      return;
    }

    this
        ._mapController
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(currentPos.latitude, currentPos.longitude),
          zoom: 13.0,
        )));

    getMarkers(currentPos.latitude, currentPos.longitude);
  }

  void setupList() async {
    var items = await DatabaseService(uid: widget.uid).getAllItems();
    setState(() {
      _items = items;
    });

    var products =
        await DatabaseService(uid: widget.uid).getUnpurchasedProducts();
    setState(() {
      _products = products;
    });
  }

  void onPressDelete(Item item) async {
    // Update DB
    await DatabaseService(uid: widget.uid).deleteItem(item);
    await DatabaseService(uid: widget.uid).updateProductsByItemId(
        item.referenceId == null ? "" : item.referenceId!,
        {columnIsDeleted: 1});

    // Update UI
    setupList();
  }

  void onPressAdd() async {
    if (this._input.isEmpty) return;

    await DatabaseService(uid: widget.uid)
        .insertItem(Item.random(_input, false));

    setupList();

    Navigator.of(context, rootNavigator: true).pop();
    // this._scrollController.animateTo(
    //     _scrollController.position.minScrollExtent,
    //     duration: Duration(milliseconds: 500),
    //     curve: Curves.fastOutSlowIn
    // );
  }

  void onPressEdit(Item item) async {
    item.title = this._input;
    await DatabaseService(uid: widget.uid).updateItem(item);

    setupList();

    Navigator.of(context, rootNavigator: true).pop();
  }

  void onClickCheckbox(Item item, bool? isChecked) async {
    // Update DB
    item.isChecked = isChecked!;
    await DatabaseService(uid: widget.uid).updateItem(item);
    await DatabaseService(uid: widget.uid).updateProductsByItemId(
        item.referenceId == null ? "" : item.referenceId!,
        {columnIsDeleted: isChecked ? 1 : 0});

    // Update UI
    setupList();
  }

  Future<void> getMarkers(double lat, double lng) async {
    var places =
        await GoogleMapsService.getPlaces(lat, lng, 'supermarket', 1500);
    for (var p in places) {
      print(
          '${p.name}\t ${p.rating}(${p.userRatingCount}) ${p.openStatus} ${p.latitude} ${p.longitude} ');
    }

    var markers = <Marker>[];
    places.forEach((place) {
      Marker marker = Marker(
          markerId: MarkerId(place.placeId),
          draggable: false,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: place.name),
          position: LatLng(place.latitude, place.longitude));

      markers.add(marker);
    });

    setState(() {
      this._markers.addAll(markers);
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initGeofence() async {
    // If the widget was removed from the tree while asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    Geofence.initialize();
    Geofence.startListening(GeolocationEvent.entry, (entry) {
      scheduleNotification("Map Shopping",
          "You are near ${entry.id.split(" ")[0]}. Buy your grocery at the store.");
    });
  }

  Future<void> initLocalNotificationPlugin() async {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  void scheduleNotification(String title, String subtitle) {
    var rng = new Random();
    Future.delayed(Duration(seconds: 1)).then((result) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your channel id', 'your channel name', 'your channel description',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          rng.nextInt(1000000), title, subtitle, platformChannelSpecifics,
          payload: 'item x');
    });
  }

  Future<dynamic> onSelectNotification(String? payload) async {
    this._pageController.animateToPage(1,
        duration: Duration(milliseconds: 1), curve: Curves.easeIn);
  }
}
