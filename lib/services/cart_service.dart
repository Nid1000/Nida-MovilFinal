class CartService {
  static final CartService _i = CartService._internal();
  factory CartService() => _i;
  CartService._internal();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get count {
    int c = 0;
    for (final it in _items) {
      c += (it['qty'] as int);
    }
    return c;
  }

  void addProduct(Map<String, dynamic> product) {
    final name = product['name'].toString();
    final index = _items.indexWhere((x) => x['name'] == name);

    if (index != -1) {
      _items[index]['qty'] = (_items[index]['qty'] as int) + 1;
    } else {
      _items.add({
        'id': (product['id'] ?? name).toString(),
        'name': name,
        'price': (product['price'] as num).toDouble(),
        'qty': 1,
      });
    }
  }

  void removeOne(String name) {
    final index = _items.indexWhere((x) => x['name'] == name);
    if (index == -1) return;
    final q = _items[index]['qty'] as int;
    if (q > 1) {
      _items[index]['qty'] = q - 1;
    } else {
      _items.removeAt(index);
    }
  }

  double get total {
    double sum = 0;
    for (final it in _items) {
      sum += (it['price'] as double) * (it['qty'] as int);
    }
    return sum;
  }

  void clear() => _items.clear();
}
