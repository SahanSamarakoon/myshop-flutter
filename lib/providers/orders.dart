import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_shop/providers/cart.dart';

class OrderItem {
  final String id;
  final List<CartItem> products;
  final double amount;
  final DateTime dateTime;
  OrderItem(
      {required this.id,
      required this.products,
      required this.amount,
      required this.dateTime});
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String? authToken;
  final String? userId;

  Orders(this.authToken, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    var url = Uri.parse(
        'https://shop-app-3971d-default-rtdb.asia-southeast1.firebasedatabase.app/oders/$userId.json?auth=$authToken');

    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<OrderItem> loadedOrders = [];
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      extractedData.forEach((orderID, orderData) {
        loadedOrders.add(OrderItem(
          id: orderID,
          amount: orderData["amount"],
          dateTime: DateTime.parse(orderData["dateTime"]),
          products: (orderData["products"] as List<dynamic>)
              .map((item) => CartItem(
                  id: item["id"],
                  price: item["price"],
                  quantity: item["quantity"],
                  title: item["title"]))
              .toList(),
        ));
      });
      _orders = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    var url = Uri.parse(
        'https://shop-app-3971d-default-rtdb.asia-southeast1.firebasedatabase.app/oders/$userId.json?auth=$authToken');
    final timeStamp = DateTime.now();
    final response = await http.post(url,
        body: json.encode({
          "amount": total,
          "dateTime": timeStamp.toIso8601String(),
          "products": cartProducts
              .map((cp) => {
                    "id": cp.id,
                    "title": cp.title,
                    "quantity": cp.quantity,
                    "price": cp.price,
                  })
              .toList(),
        }));
    _orders.insert(
        0,
        OrderItem(
            id: json.decode(response.body)["name"],
            products: cartProducts,
            amount: total,
            dateTime: timeStamp));
    notifyListeners();
  }
}
