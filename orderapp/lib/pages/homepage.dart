import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:orderapp/pages/catalog.dart';
import 'package:orderapp/pages/cart.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database db;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'orderapp.db');

    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE catalog_items (
            id INTEGER PRIMARY KEY,
            sku TEXT,
            name TEXT,
            price DECIMAL,
            stock INTEGER,
            images TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY,
            sku TEXT,
            name TEXT,
            price DECIMAL,
            stock INTEGER,
            quantity INTEGER,
            images TEXT
          )
        ''');
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/homepage_background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.4),
              BlendMode.dstATop,
            ),
          ),
        ),

        child: Stack(
          children: [
            Positioned(
              top: 120,
              left: 70,
              child: Text(
                'Welcome',
                style: GoogleFonts.pacifico(
                  textStyle: TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Button go to CatalogPage
                  SizedBox(
                    width: 200,
                    height: 60,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CatalogPage(db: db)),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 60,
                              child: Text(
                                'Catalog',
                                style: TextStyle(fontSize: 18, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Button go to CartPage
                  SizedBox(
                    width: 200,
                    height: 60,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(db: db),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 60,
                              child: Text(
                                'Cart',
                                style: TextStyle(fontSize: 18, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


