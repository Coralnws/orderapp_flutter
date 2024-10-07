import 'package:flutter_slidable/flutter_slidable.dart';
import 'customAppBar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

class CartPage extends StatefulWidget {
  final String userName;
  final String abbreviation;
  final Database db;


  const CartPage({
    super.key,
    this.userName = "Company Name",
    this.abbreviation = "CN",
    required this.db,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Database db;
  List<Map<String, dynamic>> cartList = [];
  final List<String> uom = ["UNIT", "PIECES", "KG"];

  double _calculateTotal() {
    return cartList.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  Future<void> _clearCart() async {
    await db.delete('cart_items');
    setState(() {
      cartList = [];
    });
  }

  @override
  void initState() {
    super.initState();
    db = widget.db;
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    var cartData = await db.query('cart_items');
    setState(() {
      cartList = cartData;
    });
  }

  Future<void> removeCart(String sku) async {
    await db.delete(
      'cart_items',
      where: 'sku = ?',
      whereArgs: [sku],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: CustomAppBar(
        title: "Cart",
        userName: widget.userName,
        abbreviation: widget.abbreviation,

        actions: [
          // Option button on top right
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem<int>(value: 0, child: Text('Settings')),
              PopupMenuItem<int>(value: 1, child: Text('Clear Cart')),
            ],

            onSelected: (value) {
              if (value == 1) {
                _clearCart();
              }
            }

        )
      ],
      ),

      body: Column(
        children: [
          Flexible(
            // Create cart item from cart list
            child: ListView.builder(
              itemCount: cartList.length + 1,
              itemBuilder: (context, index) {
                if (index < cartList.length) {
                  final cartItem = cartList[index];
                  // Swipe to remove a product from the cart
                  return Slidable(
                      key: ValueKey(cartItem['sku']),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        dismissible: DismissiblePane(onDismissed: () async {
                          await removeCart(cartItem['sku']);
                          setState(() {
                            fetchCartData();
                          });
                        }),
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              await removeCart(cartItem['sku']);
                              setState(() {
                                fetchCartData();
                              });
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Remove',
                          ),
                        ],
                      ),

                  child : Container(
                    padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "${index + 1}.",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        " ${cartItem['sku']}",
                                        style: TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "${cartItem['stock']} In stock",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        cartItem['name'],
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "RM${cartItem['price'].toStringAsFixed(2)}",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  child:  cartItem['images'] != null && cartItem['images'] != "" ?
                                  Image.network(
                                    cartItem['images']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/photo/product_placeholder.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                      : Image.asset(
                                    'assets/photo/product_placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 35,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 5),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 14,
                                          child: Text(
                                            "Order",
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              height: 25,
                                              child: Row(
                                                  children: [
                                                    Text(
                                                      "${cartItem['quantity']} ",
                                                      style: TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                    DropdownButton<String>(
                                                      value: uom[0],
                                                      underline: SizedBox(),
                                                      iconSize: 0,
                                                      items: uom.map((String unit) {
                                                        return DropdownMenuItem<String>(
                                                          value: unit,
                                                          child: Text(unit, style: TextStyle(fontWeight: FontWeight.w600)),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newValue) {
                                                      },
                                                    ),
                                                    Icon(Icons.arrow_forward_ios, size: 12),
                                                  ]
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 10),
                                    Container(
                                      width: 3,
                                      height: 35,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 5),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width: 4),
                                        Text("Total", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        SizedBox(width: 4),
                                        Text(
                                          "RM${(cartItem['price'] * cartItem['quantity']).toStringAsFixed(2)}",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(thickness: 1),
                      ],
                    ),
                  ),
                  );
                } else {
                  // Last row to show total amount
                  double total = cartList.fold(0, (sum, item) => sum + item['price']);
                  if(cartList.length > 0){
                    return Container(
                      padding: EdgeInsets.only(left: 20.0, right: 20.0,bottom: 10),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
                              Text("RM${total.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar:
      Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child : BottomAppBar(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total (${cartList.length})", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text("RM${_calculateTotal().toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),

              Container(
                width: 160,
                height: 50,
                // Checkout button
                child: ElevatedButton(
                  onPressed: () {
                  },
                  child: Text(
                    "Checkout",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),

                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


