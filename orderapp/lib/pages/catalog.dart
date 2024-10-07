import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'customAppBar.dart';
import 'cart.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:badges/badges.dart' as badges;

class CatalogPage extends StatefulWidget {
  final String userName;
  final String abbreviation;
  final Database db;

  const CatalogPage({
    Key? key,
    this.userName = "Company Name",
    this.abbreviation = "CN",
    required this.db,
  }) : super(key: key);

  @override
  _CatalogPageState createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> filteredProductList = [];
  TextEditingController searchController = TextEditingController();
  late Database db;
  bool hasTimedOut = false;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    db = widget.db;
    searchController.addListener(() {
      filterProducts(searchController.text);
    });

    fetchProductDataFromApi();
    _loadCartCount();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    final List<Map<String, dynamic>> cartItems = await db.query('cart_items');
    setState(() {
      cartCount = cartItems.length;
    });
  }

  void filterProducts(String query) {
    List<Map<String, dynamic>> filteredList = productList.where((product) {
      final productName = product['name'].toString().toLowerCase();
      final searchQuery = query.toLowerCase();

      return productName.contains(searchQuery);
    }).toList();

    setState(() {
      filteredProductList = filteredList;
    });
  }

  Future<String> saveImage(String imagePath,int id) async {
    try {
      var result = await Dio().get(
        imagePath,
        options: Options(responseType: ResponseType.bytes),
      );

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      File file = File('$appDocPath/${id}.jpg');

      await file.writeAsBytes(result.data);

      return file.path;
    } catch (e) {
      print("Error occurr when saving the image: $e");
      return "";
    }
  }

  Future<void> insertProductIntoDatabase(List<Map<String, dynamic>> products) async {
    await db.delete('catalog_items');
    for (var product in products) {
      String imageUrl = "";

      if (product['images'] != null && product['images'].isNotEmpty) {
        if(product['images'][0] is Map) {
          imageUrl = product['images'][0]['src_small'];
        }else{
          imageUrl = product['images'];
        }
        imageUrl = await saveImage(imageUrl,product['id']);
      }

      await db.insert('catalog_items', {
        'id' : product['id'],
        'sku': product['sku'],
        'name': product['name'],
        'price': product['sale_price'] == null ? 0.0 : product['sale_price'].toDouble(),
        'stock': product['stock_quantity'] ?? 0,
        'images': imageUrl
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductsFromDatabase() async {
    return await db.query('catalog_items');
  }

  Future<void> fetchProductDataFromApi() async {
    const url = 'https://cloud.boostorder.com/bo-mart/api/v1/wp-json/wc/v1/bo/products';
    final uri = Uri.parse(url);
    const username = 'ck_b9e4e281dc7aa5595062207a479090a390304335';
    const password = 'cs_95b5c4724a48737ed72daf8314dae9cbc83842ae';
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));

    try {
      final timeout = Future.delayed(Duration(seconds: 5), () => throw TimeoutException("Timeout"));

      final response = await Future.any([
        http.get(uri, headers: {'Authorization': basicAuth}),
        timeout,
      ]);

      if (response.statusCode == 200) {
        final body = response.body;
        final json = jsonDecode(body);

        setState(() {
          productList = List<Map<String, dynamic>>.from(json['products']);
          filteredProductList = productList;
          hasTimedOut = false;
        });

        await insertProductIntoDatabase(productList);

      } else {
        print('Failed to fetch data. Load from local database');
        var databaseList = await fetchProductsFromDatabase();
        setState(() {
          productList = databaseList;
          filteredProductList = productList;
          hasTimedOut = true;
        });
      }
    } on TimeoutException catch (e) {
      print('Timeout: 5s. Load from local database');
      productList = await fetchProductsFromDatabase();
      setState(() {
        filteredProductList = productList;
        hasTimedOut = true;
      });
    }
  }


  void _addToCart(Map<String, dynamic> productAdded,int quantity) async {
    final List<Map<String, dynamic>> existingProduct = await widget.db.query(
      'cart_items',
      where: 'sku = ?',
      whereArgs: [productAdded['sku']],
    );

    if (existingProduct.isNotEmpty) {
      final int currentQuantity = existingProduct[0]['quantity'];
      final int newQuantity = currentQuantity + quantity;

      await widget.db.update(
        'cart_items',
        {'quantity': newQuantity},
        where: 'sku = ?',
        whereArgs: [productAdded['sku']],
      );
    } else {
      await widget.db.insert('cart_items', {
        'id' : productAdded['id'],
        'sku': productAdded['sku'],
        'name': productAdded['productName'],
        'price': productAdded['price'],
        'stock' : productAdded['stock'],
        'quantity': productAdded['quantity'],
        'images': productAdded['image'],
      });
    }

    _loadCartCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Categories Name",
        userName: widget.userName,
        abbreviation: widget.abbreviation,

        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem<int>(value: 0, child: Text('Settings')),
            ],
          ),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Search Box and  Cart Icon
            Row(
              children: [
                // Search Box
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -6,end: 0),
                  badgeContent: Text(
                    cartCount.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartPage(db: db)),
                      ).then((value) {
                        _loadCartCount();
                      });;
                    },
                  ),
                ),
                // Cart Icon
              ],
            ),
            SizedBox(height: 20),
            // Product List
            Expanded(
              child: ListView.builder(
                itemCount: filteredProductList.length,
                itemBuilder: (context, index) {
                  final product = filteredProductList[index];
                  double price = product['price'] == null ?  0.0 : product['price'].toDouble();

                  if(product['images'] is List){
                    if(product['images'].isNotEmpty){
                      product['images'] = product['images'][0]['src_small'];
                    }else{
                      product['images'] = "";
                    }
                  }

                  return ProductItem(
                    sku: product['sku'],
                    productName: product['name'],
                    price: price,
                    stock: product['stock'] ?? 0,
                    image: product['images'],
                    hasTimedOut : hasTimedOut,
                    onAddToCart: _addToCart,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductItem extends StatefulWidget {
  final String sku;
  final String productName;
  final double price;
  final int stock;
  final String image;
  final bool hasTimedOut;
  final Function(Map<String, dynamic>,int) onAddToCart;

  const ProductItem({
    super.key,
    required this.sku,
    required this.productName,
    required this.price,
    required this.stock,
    required this.image,
    required this.hasTimedOut,
    required this.onAddToCart,
  });

  @override
  _ProductItemState createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  int quantity = 1;
  String selectedUnit = 'UNIT';

  void _quantityIncrease() {
    setState(() {
      quantity++;
    });
  }

  void _quantityDecrease() {
    setState(() {
      if (quantity > 1) {
        quantity--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Details and Image
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.sku,
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "${widget.stock} In stock",
                          style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      widget.productName,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    Text(
                      "RM ${widget.price.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Product Image
              Container(
                width: 70,
                height: 70,
                child: widget.hasTimedOut
                    ? (widget.image != null && widget.image != ""
                    ? Image.file(
                  File(widget.image),
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  'assets/photo/product_placeholder.png',
                  fit: BoxFit.cover,
                )
                )
                    : (widget.image != null && widget.image != ""
                    ? Image.network(
                  widget.image!,
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
                )),
              ),
            ],
          ),

          // Quantity and add to cart button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Container(),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        padding: EdgeInsets.only(left: 12.0),
                        value: selectedUnit,
                        underline: SizedBox(),
                        items: <String>['UNIT', 'PIECES', 'KG'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(fontSize: 20),),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedUnit = newValue!;
                          });
                        },
                      ),

                      Container(
                        width: 1,
                        color: Colors.grey,
                        height: 50,
                      ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: _quantityDecrease,
                            ),
                            Text(
                              quantity.toString(),
                              style: TextStyle(fontSize: 20),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _quantityIncrease,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add to cart button
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.blue, size: 40),
                onPressed: () {
                  final productAdded = {
                    'sku': widget.sku,
                    'productName': widget.productName,
                    'price': widget.price,
                    'stock': widget.stock ?? 0,
                    'quantity': quantity,
                    'image': widget.image,
                  };
                  widget.onAddToCart(productAdded,quantity);
                },
              ),

            ],
          ),
          Divider(thickness: 1),
        ],
      ),
    );
  }
}


