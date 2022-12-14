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
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:minio/minio.dart';
import 'package:minio/io.dart';
import 'package:foodie/s3access.dart';

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
      home: const HomeWidget(),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidget();
}

class _HomeWidget extends State<HomeWidget> with TickerProviderStateMixin {
  final AppinioSwiperController swipeController = AppinioSwiperController();
  http.Client _client = http.Client();
  List<Container> recipes = <Container>[];
  List<String> recipeUrls = <String>[];
  int _selectedIndex = 1;
  final searchText = TextEditingController();
  StreamSubscription? searchResponse;
  late GlobalKey<FormState> formKey;
  final storage = const FlutterSecureStorage();
  bool isAuthenticated = false;
  static List<Widget> pages = <Widget>[];
  final errorText = TextEditingController();
  AnimationController? _controllerHeart;
  Animation<double>? _animationHeart;
  late ConfettiController _controllerCenter;
  late TabController tabController;

  _HomeWidget() {
    init();
    fetchRecipes();
  }

  void init() async {
    //storage.deleteAll();
    isAuthenticated = await checkAuth();

    tabController = TabController(length: 2, vsync: this);

    _controllerCenter =
        ConfettiController(duration: const Duration(milliseconds: 500));

    _controllerHeart = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationHeart = CurvedAnimation(
      parent: _controllerHeart!,
      curve: Curves.easeOutCubic,
    );

    pages.addAll([
      RecipePage(),
      FadeIn(
          duration: Duration(milliseconds: 400),
          child: Stack(alignment: Alignment.center, children: [
            Column(children: [
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
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  controller: swipeController,
                  unlimitedUnswipe: true,
                  onSwipe: swipe,
                  cards: recipes,
                ),
              ))
            ]),
            Center(
                //alignment: Alignment.center,
                child: SizeTransition(
              sizeFactor: _animationHeart!,
              child: const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 410,
                shadows: [
                  Shadow(
                      color: Colors.black54,
                      blurRadius: 30,
                      offset: Offset(0, 2))
                ],
              ),
            )),
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                numberOfParticles: 20,
                maxBlastForce: 50,
                gravity: .5,
                confettiController: _controllerCenter,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Colors.pink,
                ],
              ),
            ),
          ])),
      AddRecipePage(
        notifyParent: notifyParent,
      )
    ]);
  }

  Future<bool> checkAuth() async {
    var token = await storage.read(key: "jwt");
    final response = await http.get(
        Uri.parse("http://10.0.2.2:8888/user/checkAuth"),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        });
    //print(response.statusCode);
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
    return FractionallySizedBox(
        widthFactor: .8,
        heightFactor: .8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image(
              width: MediaQuery.of(context).size.width * .32,
              height: MediaQuery.of(context).size.height * .12,
              image: const AssetImage("assets/images/blackLogo.png"),
            ),
            const SizedBox(
              height: 40,
            ),
            const Text(
              "Want to save a recipe?",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: 'LobsterTwo',
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  pages[0] = LoginOrSignup(true);
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade400,
                  fixedSize: Size(MediaQuery.of(context).size.width * .3,
                      MediaQuery.of(context).size.width * .1)),
              child: const Text(
                "Login",
                style: TextStyle(
                  fontSize: 16,
                  //fontFamily: "IndieFlower",
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Or",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'LobsterTwo',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  pages[0] = LoginOrSignup(false);
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: Size(MediaQuery.of(context).size.width * .3,
                      MediaQuery.of(context).size.width * .1)),
              child: const Text(
                "Sign Up",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              width: MediaQuery.of(context).size.width * .1,
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                width: 3,
                color: Colors.black,
              ))),
            )
          ]),
        ));
  }

  Future<List<Recipe>?> getSavedRecipes() async {
    final username = await storage.read(key: "username");
    print(username);
    var response =
        await http.get(Uri.parse("http://10.0.2.2:8888/userrecipes/$username"));
    print(response.body);

    if (response.body.isNotEmpty) {
      final List<dynamic> urls = jsonDecode(response.body);

      response = await http.post(
          Uri.parse("http://10.0.2.2:8888/recipe/savedRecipes"),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(urls));

      List<Recipe> recipeList = (jsonDecode(response.body) as List)
          .map((e) => Recipe.fromJson(e))
          .toList();

      return recipeList;
    } else {
      return null;
    }
  }

  Future<List<Recipe>?> getMyRecipes() async {
    final username = await storage.read(key: "username");
    print(username);
    var response = await http
        .get(Uri.parse("http://10.0.2.2:8888/userrecipes/my/$username"));
    print(response.body);

    if (response.body.isNotEmpty) {
      final List<dynamic> urls = jsonDecode(response.body);

      response = await http.post(
          Uri.parse("http://10.0.2.2:8888/recipe/savedRecipes"),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(urls));

      List<Recipe> recipeList = (jsonDecode(response.body) as List)
          .map((e) => Recipe.fromJson(e))
          .toList();

      return recipeList;
    } else {
      return null;
    }
  }

  Widget SavedRecipesPage() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TabBar(
        indicatorColor: Colors.white,
        unselectedLabelColor: Colors.white,
        labelColor: Colors.black,
        indicator: RectangularIndicator(
            color: Colors.white,
            bottomLeftRadius: 10,
            bottomRightRadius: 10,
            topLeftRadius: 10,
            topRightRadius: 10),
        controller: tabController,
        tabs: const [
          Text(
            "Saved Recipes",
            style: TextStyle(fontFamily: "LobsterTwo", fontSize: 24),
          ),
          Text(
            "My Recipes",
            style: TextStyle(fontFamily: "LobsterTwo", fontSize: 24),
          )
        ],
      ),
      body: TabBarView(controller: tabController, children: [
        // Saved recipes
        FutureBuilder(
          future: getSavedRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Container();
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return FadeIn(
                  duration: Duration(milliseconds: 400),
                  child: Container(
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
                  )));
            } else {
              return FadeIn(
                  duration: Duration(milliseconds: 400),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Oh no!\nIt looks you dont have any saved recipes.",
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: "LobsterTwo",
                                fontSize: 26),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset("assets/images/fridge.gif")),
                          const SizedBox(
                            height: 30,
                          ),
                          const Text(
                            "Swipe right on a recipe to save it.",
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: "LobsterTwo",
                                fontSize: 26),
                          ),
                        ],
                      )));
            }
          },
        ),
        // My recipes
        FutureBuilder(
          future: getMyRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Container();
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return FadeIn(
                  duration: Duration(milliseconds: 400),
                  child: Container(
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
                  )));
            } else {
              return FadeIn(
                  duration: Duration(milliseconds: 400),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white),
                      width: 200,
                      height: MediaQuery.of(context).size.height * .2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "You haven't made any recipes!",
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: "LobsterTwo",
                                fontSize: 30),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset("assets/images/book.gif")),
                          const SizedBox(
                            height: 40,
                          ),
                          const Text(
                            "Add a recipe and you'll see it here.",
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: "LobsterTwo",
                                fontSize: 30),
                          ),
                        ],
                      )));
            }
          },
        ),
      ]),
    );
  }

  Card createSavedRecipeClosedCard(Recipe recipe) {
    return Card(
      child: Column(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: FadeInImage(
              //fadeOutDuration: Duration(seconds: 1),
              //fadeInDuration: Duration(seconds: 1),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * .2,
              placeholder: randomLoading(),
              image: NetworkImage(recipe.image!),
              fit: BoxFit.fill,
              imageErrorBuilder: (context, error, stackTrace) =>
                  Image.asset("assets/images/loading.gif"),
            )),
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

  Widget createSavedRecipesCard(Recipe recipe) {
    return HoldDetector(
        onHold: () {
          deleteRecipeDialog(recipe);
        },
        child: OpenContainer(
          closedBuilder: (context, closedContainer) {
            return createSavedRecipeClosedCard(recipe);
          },
          openBuilder: (context, openContainer) {
            return createRecipeCard(recipe);
          },
          closedColor: randomColor(),
        ));
  }

  void deleteRecipeDialog(Recipe recipe) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              actionsAlignment: MainAxisAlignment.center,
              alignment: Alignment.center,
              title: const Text(
                'Delete this recipe?',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: "LobsterTwo", fontSize: 24),
              ),
              content: Text(
                recipe.title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: "IndieFlower", fontWeight: FontWeight.w600),
              ),
              actions: [
                TextButton(
                  //color: Colors.black,
                  onPressed: () async {
                    tabController.index == 0
                        ? await removeSavedRecipe(recipe)
                        : await deleteMyRecipe(recipe);

                    setState(() {
                      pages[0] = RecipePage();
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  //color: Colors.black,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child: const Text(
                    'No',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ));
  }

  Future<void> removeSavedRecipe(Recipe recipe) async {
    String? username = await storage.read(key: 'username');
    final response = await http.put(
        Uri.parse("http://10.0.2.2:8888/userrecipes/remove/$username"),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(recipe.url));

    print(response.statusCode);
    if (response.statusCode == 200) {}
  }

  Future<void> deleteMyRecipe(Recipe recipe) async {
    String? username = await storage.read(key: 'username');
    String? url = recipe.url;

    var response = await http.put(
        Uri.parse("http://10.0.2.2:8888/userrecipes/remove/my/$username"),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(url));

    if (response.statusCode == 200) {
      response = await http.delete(
        Uri.parse("http://10.0.2.2:8888/recipe/"),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(url),
      );

      print(response.statusCode);
      if (response.statusCode == 200) {
        var minio = Minio(
            endPoint: "s3.amazonaws.com",
            accessKey: getAccessKey(),
            secretKey: getsecretKey(),
            region: "us-west-2");

        var path = recipe.image!.split('com/')[1];
        print(path);

        await minio.removeObject("fooodie", path);
      }
    }
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

  AssetImage randomLoading() {
    var loadingList = [
      "assets/images/loading.gif",
      "assets/images/loading2.gif",
      "assets/images/loading3.gif",
      "assets/images/loading4.gif",
      "assets/images/loading5.gif"
    ];

    return AssetImage((loadingList..shuffle()).first);
  }

  void notifyParent() {
    setState(() {
      pages[0] = SavedRecipesPage();
      _selectedIndex = 0;
      tabController.index = 1;
    });
  }

  bool error = false;
  Widget LoginOrSignup(bool login) {
    FocusManager.instance.primaryFocus?.unfocus();
    User user = User();

    formKey = GlobalKey<FormState>();
    if (login) {
      return Form(
          key: formKey,
          child: Container(
              width: MediaQuery.of(context).size.width * .9,
              height: MediaQuery.of(context).size.height * .75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black54),
                              shape: BoxShape.circle),
                          child: IconButton(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.center,
                              onPressed: () {
                                setState(() {
                                  pages[0] = LoginOrSignupPage();
                                });
                              },
                              icon: const Icon(Icons.arrow_back_rounded)))),
                  const SizedBox(
                    height: 30,
                  ),
                  Image(
                    width: MediaQuery.of(context).size.width * .32,
                    height: MediaQuery.of(context).size.height * .12,
                    image: const AssetImage("assets/images/blackLogo.png"),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  FractionallySizedBox(
                      widthFactor: .8,
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: "Username",
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                              )),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.black54)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              )),
                        ),
                        textAlign: TextAlign.center,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter a username";
                          }
                        },
                        onSaved: (newValue) => user.Username = newValue,
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  FractionallySizedBox(
                      widthFactor: .8,
                      child: TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                              )),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black54,
                              )),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              )),
                        ),
                        textAlign: TextAlign.center,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter a password";
                          }
                        },
                        onSaved: (newValue) => user.Password = newValue,
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  Visibility(
                      maintainSize: error,
                      maintainAnimation: error,
                      maintainState: error,
                      visible: error,
                      child: const Text(
                        "Incorrect username or password.",
                        style: TextStyle(color: Colors.red, fontSize: 15),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final form = formKey.currentState!;
                      if (form.validate()) {
                        form.save();

                        final request = await http.post(
                            Uri.parse("http://10.0.2.2:8888/user/login"),
                            headers: <String, String>{
                              'Content-Type': 'application/json'
                            },
                            body: jsonEncode(user.toJson()));

                        if (request.statusCode == 200) {
                          Map<String, dynamic> data = jsonDecode(request.body);

                          print(data);

                          await storage.write(key: "jwt", value: data['token']);
                          await storage.write(
                              key: "username", value: data['username']);
                          isAuthenticated = true;

                          setState(() {
                            pages[0] = RecipePage();
                          });
                        } else {
                          ////////// incorrect username/password
                          setState(() {
                            error = true;
                            //error == true ? error = false : error = true;
                            pages[0] = LoginOrSignup(true);
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue.shade400,
                      fixedSize: Size(MediaQuery.of(context).size.width * .3,
                          MediaQuery.of(context).size.height * .05),
                      //elevation: 2,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        //fontFamily: "LobsterTwo",
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * .1,
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                      width: 3,
                      color: Colors.black,
                    ))),
                  )
                ],
              )));
    }

    return Form(
        key: formKey,
        child: Container(
            width: MediaQuery.of(context).size.width * .9,
            height: MediaQuery.of(context).size.height * .8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView(
              //padding: const EdgeInsets.only(left: 20, right: 20),
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            shape: BoxShape.circle),
                        child: IconButton(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.center,
                            onPressed: () {
                              setState(() {
                                pages[0] = LoginOrSignupPage();
                              });
                            },
                            icon: const Icon(Icons.arrow_back_rounded)))),
                const SizedBox(
                  height: 10,
                ),
                Image(
                  width: MediaQuery.of(context).size.width * .32,
                  height: MediaQuery.of(context).size.height * .12,
                  image: const AssetImage("assets/images/blackLogo.png"),
                ),
                const SizedBox(
                  height: 30,
                ),
                FractionallySizedBox(
                    widthFactor: .8,
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.black54)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            )),
                      ),
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter an Email";
                        }
                      },
                      onSaved: (newValue) => user.Email = newValue,
                    )),
                const SizedBox(
                  height: 20,
                ),
                FractionallySizedBox(
                    widthFactor: .8,
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "Username",
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.black54)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            )),
                      ),
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter a username";
                        }
                      },
                      onSaved: (newValue) => user.Username = newValue,
                    )),
                const SizedBox(
                  height: 20,
                ),
                FractionallySizedBox(
                    widthFactor: .8,
                    child: TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.black54)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            )),
                      ),
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter a password";
                        }
                        user.Password = value;
                      },
                      onSaved: (newValue) => user.Password = newValue,
                    )),
                const SizedBox(
                  height: 20,
                ),
                FractionallySizedBox(
                    widthFactor: .8,
                    child: TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Confirm password",
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.black54)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            )),
                      ),
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value!.isEmpty || value != user.Password) {
                          return "Passwords must match";
                        }
                      },
                      //onSaved: (newValue) => user.Username = newValue,
                    )),
                const SizedBox(
                  height: 10,
                ),
                FractionallySizedBox(
                    widthFactor: .3,
                    child: ElevatedButton(
                      onPressed: () async {
                        final form = formKey.currentState!;
                        if (form.validate()) {
                          form.save();

                          final request = await http.post(
                              Uri.parse("http://10.0.2.2:8888/user/"),
                              headers: <String, String>{
                                'Content-Type': 'application/json'
                              },
                              body: jsonEncode(user.toJson()));

                          if (request.statusCode == 200) {
                            Map<String, dynamic> data =
                                jsonDecode(request.body);

                            await storage.write(
                                key: "jwt", value: data['token']);
                            await storage.write(
                                key: "username", value: data['username']);
                            isAuthenticated = true;

                            setState(() {
                              pages[0] = RecipePage();
                            });
                          } else if (request.statusCode == 409) {
                            /////////////////////// Username taken
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue.shade400,
                          fixedSize: Size(20, 30)),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )),
              ],
            )));
  }

  void swipe(int index, AppinioSwiperDirection direction) async {
    if (direction == AppinioSwiperDirection.right) {
      if (isAuthenticated) {
        String? username = await storage.read(key: 'username');
        final response = await http.put(
            Uri.parse("http://10.0.2.2:8888/userrecipes/$username"),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(recipeUrls[index]));

        _controllerCenter.play();
        await _controllerHeart!.forward();
        _controllerHeart!.animateBack(0, duration: Duration(milliseconds: 500));

        pages[0] = SavedRecipesPage();
      } else {
        swipeController.unswipe();
        showDialog(
            context: context,
            builder: (BuildContext context) => SimpleDialog(
                  title: const Center(
                      child: Text(
                    "Want to save a recipe?",
                    style: TextStyle(fontFamily: "LobsterTwo"),
                  )),
                  children: [
                    TextButton(
                        //style: TextButton.styleFrom(backgroundColor: Colors.black),
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
                            pages[0] = LoginOrSignup(false);
                            _selectedIndex = 0;
                          });
                        },
                        child: Text("Sign Up"))
                  ],
                ));
        return;
      }
    }
    recipeUrls.removeLast();
  }

  void fetchRecipes() async {
    final response =
        await http.get(Uri.parse("http://10.0.2.2:8888/recipe/random"));
    print(response.body);
    List<dynamic> recipeList = jsonDecode(response.body);

    if (recipes.length >= 2) {
      recipes.removeRange(0, recipes.length - 1);
      recipeUrls.removeRange(0, recipeUrls.length - 1);
    }

    recipeList.forEach((recipe) {
      recipe = Recipe.fromJson(recipe);
      setState(() {
        recipes.insert(0, createRecipeCard(recipe));
        recipeUrls.insert(0, recipe.url);
      });
    });
  }

  void getRecipes(String searchTerm) async {
    bool dbHasRecipe = false;
    FocusManager.instance.primaryFocus?.unfocus();
    if (searchResponse != null && !searchResponse!.isPaused) {
      searchResponse!.cancel();
    }

    //searchTerm.replaceAll(" ", "%20");
    if (searchTerm.isEmpty) {
      fetchRecipes();
      return;
    } else {
      var dbResponse = await http
          .get(Uri.parse("http://10.0.2.2:8888/recipe/search/$searchTerm"));

      List<dynamic> recipeList = jsonDecode(dbResponse.body);

      if (dbResponse.body.isNotEmpty) {
        dbHasRecipe = true;

        if (recipes.length >= 2) {
          recipes.removeRange(0, recipes.length - 1);
          recipeUrls.removeRange(0, recipeUrls.length - 1);
        }

        recipeList.forEach((recipe) {
          recipe = Recipe.fromJson(recipe);
          setState(() {
            recipes.insert(0, createRecipeCard(recipe));
            recipeUrls.insert(0, recipe.url);
          });
        });
      }
    }

    var request = http.Request(
        "GET", Uri.parse("http://10.0.2.2:8888/scraper/$searchTerm"));
    //request.headers["Cache-Control"] = "no-cache";
    //request.headers["Accept"] = "text/event-stream";

    Future<http.StreamedResponse> response = _client.send(request);
    print("Searching...");
    response.asStream().listen((streamedResponse) {
      print(
          "Received streamedResponse.statusCode:${streamedResponse.statusCode}");

      if (!dbHasRecipe && recipes.length >= 2) {
        recipes.removeRange(0, recipes.length - 1);
        recipeUrls.removeRange(0, recipeUrls.length - 1);
      }

      String jsonString = '';
      try {
        searchResponse = streamedResponse.stream.listen((data) {
          jsonString += utf8.decode(data);
          print(jsonString);

          if (jsonString.endsWith('}')) {
            Recipe recipe = Recipe.fromJsonSearch(jsonDecode(jsonString));
            recipes.insert(0, createRecipeCard(recipe));
            recipeUrls.insert(0, recipe.url!);

            //print(recipes);
            jsonString = "";
            setState(() {});
          }
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
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FadeInImage(
                  key: UniqueKey(),
                  //fadeOutDuration: Duration(seconds: 1),
                  //fadeInDuration: Duration(seconds: 1),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * .5,
                  placeholder: const AssetImage("assets/images/loading.gif"),
                  image: NetworkImage(recipe.image!),
                  fit: BoxFit.fill,
                  imageErrorBuilder: (context, error, stackTrace) =>
                      Image.asset("assets/images/loading.gif"),
                )),
            // Container(
            //   height: MediaQuery.of(context).size.height * .5,
            //   width: MediaQuery.of(context).size.width,
            //   alignment: Alignment.center,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20),
            //     image: DecorationImage(
            //       image: FadeInImage(image: NetworkImage(recipe.image!), placeholder: const AssetImage("assets/images/loading.gif"),).placeholder, fit: BoxFit.cover
            //     ),
            //   ),
            // ),

            //title
            Container(
                margin: const EdgeInsets.all(10),
                alignment: Alignment.center,
                child: AutoSizeText(
                  recipe?.title ?? "No title",
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'LobsterTwo'),
                  maxLines: 1,
                )),

            //author, time, yield
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  Icon(Icons.face, color: Colors.blue[300], size: 30),
                  AutoSizeText(
                    "By: ${recipe?.author ?? 'N/A'}",
                    style: const TextStyle(
                        fontFamily: 'IndieFlower',
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ]),
                Column(children: [
                  Icon(Icons.timer, color: Colors.red[600], size: 30),
                  Text(
                    "Prep time: ${recipe.time != null ? "${recipe.time.toString()} minutes" : '???'}",
                    style: const TextStyle(
                        fontFamily: 'IndieFlower',
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ]),
                Column(children: [
                  Icon(
                    Icons.restaurant,
                    color: Colors.green[700],
                    size: 30,
                  ),
                  Text(
                    recipe?.yeild ?? 'N/A',
                    style: const TextStyle(
                        fontFamily: 'IndieFlower',
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
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
                          fontSize: 25, fontFamily: 'LobsterTwo'),
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
                        fontFamily: 'IndieFlower',
                        fontWeight: FontWeight.w600,
                        fontSize: 20),
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
                    child: const Text(
                      "Instructions",
                      style: TextStyle(fontSize: 25, fontFamily: 'LobsterTwo'),
                    ))),
            //instructions
            Column(
              children: recipe.instructions!.map((r) {
                instructionsCount++;
                return ListTile(
                  title: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: "$instructionsCount. ",
                          style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'IndieFlower',
                              fontWeight: FontWeight.w800,
                              fontSize: 22)),
                      TextSpan(
                          text: r,
                          style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'IndieFlower',
                              fontWeight: FontWeight.w700,
                              fontSize: 20)),
                    ]),
                  ),
                );
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
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            width: MediaQuery.of(context).size.width * .8,
            height: MediaQuery.of(context).size.height * .4,
            image: const AssetImage("assets/images/logoWhite.png"),
          ),
          LoadingAnimationWidget.inkDrop(color: Colors.white, size: 50)
        ],
      ));
    } else {
      return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black,
          body: SafeArea(child: Center(child: pages.elementAt(_selectedIndex))),
          bottomNavigationBar: BottomNavigationBar(
            iconSize: 28,
            selectedFontSize: 16,
            type: BottomNavigationBarType.shifting,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Recipes',
                backgroundColor: Colors.lightBlue[400],
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
                backgroundColor: Colors.deepOrange[400],
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Add Recipe',
                backgroundColor: Colors.yellow[700],
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            onTap: _onItemTapped,
          ));
    }
  }
}
