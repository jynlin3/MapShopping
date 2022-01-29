import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_shopper/models/search_log.dart';
import 'package:map_shopper/services/firestore.dart';
import 'package:transparent_image/transparent_image.dart';

import '../models/product.dart';
import '../services/pricecomparisonengine.dart';

class PriceSearch extends StatefulWidget {
  final String title;
  final String itemId;
  final String uid;

  const PriceSearch(
      {Key? key, required this.title, required this.itemId, required this.uid})
      : super(key: key);

  @override
  _PriceSearchState createState() => _PriceSearchState();
}

class _PriceSearchState extends State<PriceSearch> {
  String _title = "";
  String _itemId = "";

  late Future<List<Product>> _futureProducts;
  late DatabaseService _databaseService;
  late SearchLog _searchLog;

  @override
  void initState() {
    // The method will be called when the widget is inserted into the tree for the first time.
    // It will only be called once. Usually, the data is initialized in this method.

    super.initState();

    _title = widget.title;
    _itemId = widget.itemId;
    _databaseService = DatabaseService(uid: widget.uid);
    _futureProducts = fetchRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_title),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                _databaseService.insertSearchLog(_searchLog);
                Navigator.pop(context);
              })),
      body: FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            var products = snapshot.data ?? [];
            if (products.length == 0) {
              return Center(
                child: Text("Failed to search. Please try again."),
              );
            }
            return ListView.builder(
                itemCount: products.length,
                itemBuilder: (BuildContext context, int index) {
                  return ProductCard(
                      product: products[index],
                      databaseService: _databaseService);
                });
          }),
    );
  }

  Future<List<Product>> fetchRecommendations() async {
    var saveProducts = await DatabaseService(uid: widget.uid).getAllProducts();
    String userHistory = saveProducts.map((p) => p.name).join(",");

    List<int> rankingOfBookmarks = [];
    var recommendations =
        await PriceComparisonEngineParser.fetch(_title, userHistory, _itemId);
    recommendations.asMap().forEach((index, r) {
      for (var p in saveProducts) {
        if (r.name == p.name) {
          r.isDeleted = false;
          r.referenceId = p.referenceId;
          rankingOfBookmarks.add(index);
        }
      }
    });

    _searchLog = SearchLog(
        queryString: _title,
        userHistory: userHistory,
        rankingOfBookmarks: rankingOfBookmarks,
        time: DateTime.now().toUtc());

    return recommendations;
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final DatabaseService databaseService;

  const ProductCard(
      {Key? key, required this.product, required this.databaseService})
      : super(key: key);

  @override
  ProductCardState createState() => ProductCardState();
}

class ProductCardState extends State<ProductCard> {
  late bool _isBookmarked;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _isBookmarked = !widget.product.isDeleted;
    _productId = widget.product.referenceId;
  }

  @override
  Widget build(BuildContext context) {
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
            image: widget.product.imageURL,
            placeholder: kTransparentImage,
          ),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text(widget.product.name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("${widget.product.store}  ${widget.product.distance}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                SizedBox(height: 8),
                Text("\$ ${widget.product.price}",
                    style: const TextStyle(
                        fontSize: 21,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    icon: _isBookmarked
                        ? Icon(Icons.bookmark)
                        : Icon(Icons.bookmark_border),
                    onPressed: () {
                      if (_isBookmarked)
                        onPressDelete();
                      else
                        onPressAdd();
                    }),
              ])),
        ],
      ),
    );
  }

  void onPressAdd() async {
    //TODO: Check if the store is added.

    DocumentReference newDoc =
        await widget.databaseService.insertProduct(widget.product);

    setState(() {
      _isBookmarked = true;
      _productId = newDoc.id;
    });

    //TODO: Find nearby stores in 6 miles (10 min drive).
    //TODO: Add nearby stores to db and geofence.
  }

  void onPressDelete() async {
    if (_productId != null)
      await widget.databaseService.deleteProduct(_productId!);

    setState(() {
      _isBookmarked = false;
      _productId = null;
    });

    //TODO: Check if the store should be deleted.
    //TODO: Remove all stores from geofence.
    //TODO: Iterate over the remaining stores and add them to geofence.
  }
}
