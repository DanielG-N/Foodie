import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodie/addRecipePage.dart';
import 'package:foodie/recipe.dart';
import 'package:foodie/user.dart';
import 'package:http/http.dart' as http;
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:animations/animations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodie',
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
  List<String> recipeUrls = <String>[];
  int _selectedIndex = 1;
  final searchText = TextEditingController();
  StreamSubscription? searchResponse;
  late GlobalKey<FormState> formKey;
  final storage = FlutterSecureStorage();
  bool isAuthenticated = false;
  static List<Widget> pages = <Widget>[];

  _TestWidget() {
    init();
    fetchRecipes();
  }

  void init() async {
    isAuthenticated = await checkAuth();

    pages.addAll([
      RecipePage(),
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
                unlimitedUnswipe: true,
                onSwipe: swipe,
                cards: recipes,
              ),
            ))
          ])),
      const AddRecipePage()
    ]);
  }

  Future<bool> checkAuth() async {
    var token = await storage.read(key: "jwt");
    final response = await http.get(
        Uri.parse("http://10.0.2.2:9005/user/checkAuth"),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        });
    print(response.statusCode);
    if (response.statusCode == 401) {
      return false;
    } else {
      return true;
    }
  }

  Widget RecipePage() {
    return isAuthenticated ? SavedRecipesPage() : LoginOrSignupPage();
  }

  Widget LoginOrSignupPage() {
    return Container(
        child: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              pages[0] = LoginOrSignup(true);
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("Login"),
        ),
        const Text(
          "Or",
          style: TextStyle(color: Colors.white),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              pages[0] = LoginOrSignup(false);
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ]),
    ));
  }

  Future<List<Recipe>?> getSavedRecipes() async {
    final username = await storage.read(key: "username");
    print(username);
    var response =
        await http.get(Uri.parse("http://10.0.2.2:9003/userrecipes/$username"));
    print(response.body);

    if (response.body.isNotEmpty) {
      final List<dynamic> urls = jsonDecode(response.body);

      response = await http.post(
          Uri.parse("http://10.0.2.2:9001/recipe/savedRecipes"),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(urls));

      List<Recipe> recipeList = (jsonDecode(response.body) as List)
          .map((e) => Recipe.fromJson(e))
          .toList();

      return recipeList;
    } else {
      return null;
    }

    // recipeList.forEach((recipe) {
    //   recipe = Recipe.fromJson(recipe);
    // });
  }

  Widget SavedRecipesPage() {
    return FutureBuilder(
      future: getSavedRecipes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
              child: CustomScrollView(
            primary: false,
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.count(
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                  children: <Widget>[
                    for (var recipe in snapshot.data!)
                      createSavedRecipesCard(recipe)
                  ],
                ),
              ),
            ],
          ));
        } else {
          return Container();
        }
      },
    );
  }

  Card createSavedRecipeClosedCard(Recipe recipe) {
    return Card(
      child: Column(children: [
        Container(
          height: MediaQuery.of(context).size.height * .2,
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            image: DecorationImage(
                image: NetworkImage(recipe.image!), fit: BoxFit.cover),
          ),
        ),
        Container(
            margin: const EdgeInsets.only(top: 4),
            alignment: Alignment.center,
            child: AutoSizeText(
              recipe?.title ?? "No title",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'LobsterTwo'),
              maxLines: 1,
            )),
      ]),
    );
  }

  OpenContainer createSavedRecipesCard(Recipe recipe) {
    return OpenContainer(
      closedBuilder: (context, closedContainer) {
        return createSavedRecipeClosedCard(recipe);
      },
      openBuilder: (context, openContainer) {
        return createRecipeCard(recipe);
      },
      closedColor: randomColor(),
    );
  }

  Color randomColor() {
    var colorList = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.yellow.shade300,
      Colors.purple.shade400,
      Colors.pink.shade300,
      Colors.orange.shade300,
      Colors.teal.shade300
    ];

    return (colorList..shuffle()).first;
  }

  Widget LoginOrSignup(bool login) {
    FocusManager.instance.primaryFocus?.unfocus();
    User user = User();

    formKey = GlobalKey<FormState>();
    if (login) {
      return Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "Username",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter a username";
                  }
                },
                onSaved: (newValue) => user.Username = newValue,
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(backgroundColor: Colors.white),
                  hintText: "Password",
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter your password";
                  }
                },
                onSaved: (newValue) => user.Password = newValue,
              ),
              ElevatedButton(
                onPressed: () async {
                  final form = formKey.currentState!;
                  if (form.validate()) {
                    form.save();

                    final request = await http.post(
                        Uri.parse("http://10.0.2.2:9005/user/login"),
                        headers: <String, String>{
                          'Content-Type': 'application/json'
                        },
                        body: jsonEncode(user.toJson()));

                    if (request.statusCode == 200) {
                      Map<String, dynamic> data = jsonDecode(request.body);

                      await storage.write(key: "jwt", value: data['token']);
                      await storage.write(
                          key: "username", value: data['username']);
                      isAuthenticated = true;
                    }
                  }
                  setState(() {
                    //////////////////////////////////////////
                    pages[0] = RecipePage();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ));
    }

    return Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(backgroundColor: Colors.white),
                hintText: "Email",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter an email";
                }
              },
              onSaved: (newValue) => user.Email = newValue,
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "Username",
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return "Please enter a username";
                }
              },
              onSaved: (newValue) => user.Username = newValue,
            ),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(backgroundColor: Colors.white),
                hintText: "Password",
              ),
              validator: (value) {
                user.Password = value;
                if (value!.isEmpty) {
                  return "Please enter a password";
                }
              },
              onSaved: (newValue) => user.Password = newValue,
            ),
            // TextFormField(
            //   obscureText: true,
            //   decoration: const InputDecoration(
            //     filled: true,
            //     fillColor: Colors.white,
            //     labelStyle: TextStyle(backgroundColor: Colors.white),
            //     hintText: "Confirm Password",
            //   ),
            //   validator: (value) {
            //     if (value!.isEmpty || value != user.Password) {
            //       return "Passwords must match";
            //     }
            //   },
            //   onSaved: (newValue) => user.Password = newValue,
            // ),
            ElevatedButton(
              onPressed: () async {
                final form = formKey.currentState!;
                if (form.validate()) {
                  form.save();

                  final request = await http.post(
                      Uri.parse("http://10.0.2.2:9005/user/"),
                      headers: <String, String>{
                        'Content-Type': 'application/json'
                      },
                      body: jsonEncode(user.toJson()));

                  if (request.statusCode == 200) {
                    Map<String, dynamic> data = jsonDecode(request.body);

                    await storage.write(key: "jwt", value: data['token']);
                    await storage.write(
                        key: "username", value: data['username']);
                    isAuthenticated = true;
                  }
                }
                setState(() {
                  /////////////////////////// Do stuff
                  pages[0] = RecipePage();
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                "Sign Up",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ));
  }

  void swipe(int index, AppinioSwiperDirection direction) async {
    if (direction == AppinioSwiperDirection.right) {
      if (isAuthenticated) {
        String? username = await storage.read(key: 'username');
        final response = await http.put(
            Uri.parse("http://10.0.2.2:9003/userrecipes/$username"),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(recipeUrls[index]));
        pages[0] = SavedRecipesPage();
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) => SimpleDialog(
                  title: Text("Want to save a recipe?"),
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            pages[0] = LoginOrSignup(true);
                            _selectedIndex = 0;
                          });
                        },
                        child: Text("Login")),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            LoginOrSignup(false);
                            _selectedIndex = 0;
                          });
                        },
                        child: Text("Sign Up"))
                  ],
                ));
      }
    }
    recipeUrls.removeLast();
  }

  void fetchRecipes() async {
    final response =
        await http.get(Uri.parse("http://10.0.2.2:9001/recipe/random"));
    print(response.body);
    List<dynamic> recipeList = jsonDecode(response.body);

    setState(() {
      recipeList.forEach((recipe) {
        recipe = Recipe.fromJson(recipe);
        recipes.add(createRecipeCard(recipe));
        recipeUrls.add(recipe.url);
      });
    });
  }

  void getRecipes(String searchTerm) async {
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
    response.asStream().listen((streamedResponse) {
      print(
          "Received streamedResponse.statusCode:${streamedResponse.statusCode}");

      if (recipes.length >= 3) {
        //recipes.removeRange(0, recipes.length - 2);
        recipes.clear();
      }

      try {
        searchResponse = streamedResponse.stream.listen((data) {
          Recipe recipe = Recipe.fromJson(jsonDecode((utf8.decode(data))));
          recipes.insert(0, createRecipeCard(recipe));
          recipeUrls.insert(0, recipe.url!);

          print(recipes);
          setState(() {});
        });
      } catch (e) {
        print("Caught $e");
      }
    });
  }

  Container createRecipeCard(Recipe recipe) {
    int instructionsCount = 0;

    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: Colors.white),
        child: ListView(
          children: [
            //image
            Container(
              height: MediaQuery.of(context).size.height * .5,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                    image: NetworkImage(recipe.image!), fit: BoxFit.cover),
              ),
            ),

            //title
            Container(
                margin: const EdgeInsets.all(10),
                alignment: Alignment.center,
                child: AutoSizeText(
                  recipe?.title ?? "No title",
                  style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'LobsterTwo'),
                  maxLines: 1,
                )),

            //author, time, yield
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  Icon(
                    Icons.face,
                    color: Colors.blue[300],
                  ),
                  Text(
                    "By: ${recipe?.author ?? 'N/A'}",
                    style: const TextStyle(
                        fontFamily: 'IndieFlower', fontWeight: FontWeight.w600),
                  ),
                ]),
                Column(children: [
                  Icon(
                    Icons.timer,
                    color: Colors.red[700],
                  ),
                  Text(
                    "Prep time: ${recipe?.time.toString() ?? 'N/A'}",
                    style: const TextStyle(
                        fontFamily: 'IndieFlower', fontWeight: FontWeight.w600),
                  ),
                ]),
                Column(children: [
                  Icon(
                    Icons.restaurant,
                    color: Colors.green[800],
                  ),
                  Text(
                    recipe?.yeild ?? 'N/A',
                    style: const TextStyle(
                        fontFamily: 'IndieFlower', fontWeight: FontWeight.w600),
                  ),
                ])
              ],
            ),

            Center(
                child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                        width: 3,
                      )),
                    ),
                    child: Text(
                      "${recipe.ingredients!.length} Ingredients",
                      style: const TextStyle(
                          fontSize: 20, fontFamily: 'LobsterTwo'),
                    ))),
            //ingredients
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: recipe.ingredients!.map((r) {
                return ListTile(
                  style: ListTileStyle.list,
                  visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  title: Text(
                    r,
                    style: const TextStyle(
                        fontFamily: 'IndieFlower', fontWeight: FontWeight.w600),
                  ),
                  leading: Icon(
                    Icons.circle,
                    color: Colors.grey[850],
                    size: 10,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  minLeadingWidth: 0,
                );
              }).toList(),
            ),

            //instructions
            Column(
              children: recipe.instructions!.map((r) {
                instructionsCount++;
                return ListTile(title: Text('$instructionsCount. $r'));
              }).toList(),
            ),
          ],
        ));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(child: Center(child: pages.elementAt(_selectedIndex))),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Recipes',
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
