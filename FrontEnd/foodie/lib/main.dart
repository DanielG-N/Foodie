import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodie/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:appinio_swiper/appinio_swiper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const TestWidget(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String body = "";
  dynamic json;
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidget();
}

class _TestWidget extends State<TestWidget> {
  http.Client _client = http.Client();
  List<Container> recipes = <Container>[];
  int _selectedIndex = 1;
  final searchText = TextEditingController();
  StreamSubscription? searchResponse;

  static List<Widget> pages = <Widget>[
    Text(
      'Index 1: Business',
    ),
  ];

  _TestWidget() {
    pages.addAll([
      Container(
          height: double.infinity,
          width: double.infinity,
          child: Column(children: [
            TextField(
              controller: searchText,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      getRecipes(searchText.text);
                    }),
                suffixIconColor: Colors.white,
                filled: true,
                fillColor: Colors.white,
                //contentPadding: EdgeInsets.only(top: 50),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                hintText: "Search recipes",
              ),
              onEditingComplete: () => getRecipes(searchText.text),
            ),
            Expanded(
                child: FractionallySizedBox(
              child: AppinioSwiper(
                cards: recipes,
              ),
            ))
          ])),
      Text(
        'Index 2: School',
      ),
    ]);
    getRecipes("chicken");
  }

  void getRecipes(String searchTerm) async {
    //_client = http.Client();
    FocusManager.instance.primaryFocus?.unfocus();
    if (searchResponse != null && !searchResponse!.isPaused) {
      searchResponse!.cancel();
    }

    var request =
        http.Request("GET", Uri.parse("http://10.0.2.2:9000/$searchTerm"));
    //request.headers["Cache-Control"] = "no-cache";
    //request.headers["Accept"] = "text/event-stream";

    Future<http.StreamedResponse> response = _client.send(request);
    print("Searching...");
    searchResponse = response.asStream().listen((streamedResponse) {
      print(
          "Received streamedResponse.statusCode:${streamedResponse.statusCode}");
      if (recipes.length >= 3) {
        recipes.removeRange(0, recipes.length - 2);
      }
      try {
        streamedResponse.stream.listen((data) {
          //print("Received data:${utf8.decode(data)}");
          Recipe recipe = Recipe.fromJson(jsonDecode((utf8.decode(data))));
          int instructionsCount = 0;

          recipes.insert(
              0,
              Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white),
                  child: ListView(
                    //padding: const EdgeInsets.all(50),
                    children: [
                      //image
                      Container(
                        height: MediaQuery.of(context).size.height * .5,
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                              image: NetworkImage(recipe.image!),
                              fit: BoxFit.cover),
                        ),
                      ),

                      //title
                      Container(
                          margin: const EdgeInsets.all(10),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            recipe?.title ?? "No title",
                            style: const TextStyle(fontSize: 25),
                          )),
                      //author, time, yield
                      Row(
                        children: [
                          Text(recipe?.author ?? "N/A"),
                          Text(recipe?.time.toString() ?? "N/A"),
                          Text(recipe?.yeild ?? "N/A")
                        ],
                      ),
                      //ingredients
                      Column(
                        children: recipe.ingredients!.map((r) {
                          return ListTile(title: Text(r));
                        }).toList(),
                      ),
                      //instructions
                      Column(
                        children: recipe.instructions!.map((r) {
                          instructionsCount++;
                          return ListTile(
                              title: Text('$instructionsCount. $r'));
                        }).toList(),
                      ),
                    ],
                  )));
          print(recipes);
          setState(() {});
        });
      } catch (e) {
        print("Caught $e");
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (recipes.length == 0) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(child: Center(child: pages.elementAt(_selectedIndex))),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Business',
                backgroundColor: Colors.green,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
                backgroundColor: Colors.red,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
                backgroundColor: Colors.pink,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[800],
            onTap: _onItemTapped,
          ));
    }
  }
}
