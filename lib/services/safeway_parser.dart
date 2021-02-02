import 'package:html/dom.dart' as DOM;

import '../models/product.dart';

class SafewayParser {
  static String _urlBase = 'https://www.safeway.com/shop/search-results.html';

  static String getURL(String searchTerm){
    return _urlBase + '?q=' + searchTerm + '&sort=price';
  }

  static String _findName(DOM.Element productDiv){
    return productDiv.querySelector('a.product-title').innerHtml.trim();
  }
  
  static double _findPrice(DOM.Element productDiv){
    var strPrice = productDiv.querySelector('span.product-price').innerHtml;
    var words = strPrice.split(' ');

    double price = 0;
    for (var w in words) {
      if (w.startsWith('\$')){
        price = double.parse(w.split('\$')[1]);
        break;
      }
    }
    return price;
  }

  static String _findImageURL(DOM.Element productDiv){
    if (productDiv.querySelector('img.ab-lazy').attributes.containsKey('src')){
      return productDiv.querySelector('img.ab-lazy').attributes['src'];
    } else {
      return 'https://www.stma.org/wp-content/uploads/2017/10/no-image-icon.png';
    }
  }

  static List<Product> collectProducts(DOM.Document dom){
    List<DOM.Element> divs = dom.querySelectorAll('div.product-item-inner');
    List<Product> products = [];
    for (var div in divs){
      // filter products without price
      var price = _findPrice(div);
      if (price <= 0)
        continue;

      products.add(Product(
          _findName(div),
          price,
          'Safeway',
          _findImageURL(div),
          ''
      ));
    }
    return products;
  }
}