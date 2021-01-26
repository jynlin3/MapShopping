import 'package:html/dom.dart' as DOM;

import 'product.dart';

class SafewayParser {
  static String _urlBase = 'https://www.safeway.com/shop/search-results.html';

  static String getURL(String searchTerm){
    return _urlBase + "?q=" + searchTerm + "&sort=price";
  }

  static String findName(DOM.Element productDiv){
    return productDiv.querySelector('a.product-title').innerHtml.trim();
  }
  
  static double findPrice(DOM.Element productDiv){
    var strPrice = productDiv.querySelector('span.product-price').innerHtml;
    var words = strPrice.split(" ");

    double price = 0;
    for (var w in words) {
      if (w.startsWith("\$")){
        price = double.parse(w.split("\$")[1]);
        break;
      }
    }
    return price;
  }

  static String findImageURL(DOM.Element productDiv){
    return productDiv.querySelector('img.ab-lazy').attributes['src'];
  }

  static List<Product> collectProducts(DOM.Document dom){
    List<DOM.Element> divs = dom.querySelectorAll("div.product-item-inner");
    List<Product> products = [];
    for (var div in divs){
      products.add(Product(
          findName(div),
          findPrice(div),
          "Safeway",
          findImageURL(div),
          ""
      ));
    }
    return products;
  }
}