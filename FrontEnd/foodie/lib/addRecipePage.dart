import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:foodie/ImagePicker.dart';
import 'package:foodie/recipe.dart';
import 'package:foodie/s3access.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:minio/minio.dart';
import 'package:minio/io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_fadein/flutter_fadein.dart';

class AddRecipePage extends StatefulWidget {
  final Function notifyParent;
  const AddRecipePage({super.key, required this.notifyParent});

  @override
  State<AddRecipePage> createState() => _AddRecipePage();
}

class _AddRecipePage extends State<AddRecipePage>
    with TickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  Recipe recipe = Recipe(ingredients: [], instructions: []);
  final formKey = GlobalKey<FormState>();
  int ingredientsIndex = 7;
  int instructionsIndex = 10;
  List<Widget> formWidgets = [];
  XFile? image;
  AnimationController? _controllerAddIngredient;
  Animation<double>? _animationAddIngredient;
  AnimationController? _controllerRemoveIngredient;
  Animation<double>? _animationRemoveIngredient;

  AnimationController? _controllerAddInstruction;
  Animation<double>? _animationAddInstruction;
  AnimationController? _controllerRemoveInstruction;
  Animation<double>? _animationRemoveInstruction;

  AnimationController? _controllerCheck;
  Animation<double>? _animationCheck;

  @override
  void initState() {
    super.initState();

    _controllerAddIngredient = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animationAddIngredient =
        Tween<double>(begin: .5, end: 1).animate(_controllerAddIngredient!);

    _controllerRemoveIngredient = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationRemoveIngredient = CurvedAnimation(
      parent: _controllerRemoveIngredient!,
      curve: Curves.linear,
    );

    _controllerAddInstruction = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animationAddInstruction =
        Tween<double>(begin: .5, end: 1).animate(_controllerAddInstruction!);

    _controllerRemoveInstruction = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationRemoveInstruction = CurvedAnimation(
      parent: _controllerRemoveInstruction!,
      curve: Curves.linear,
    );

    _controllerCheck = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationCheck = CurvedAnimation(
      parent: _controllerCheck!,
      curve: Curves.easeOutCubic,
    );

    formWidgets.addAll([
      const SizedBox(
        height: 20,
      ),
      const Text(
        "Add a recipe",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.black, fontFamily: "LobsterTwo", fontSize: 20),
      ),
      TextFormField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          hintText: "Title",
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue.shade400,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              )),
        ),
        textAlign: TextAlign.center,
        validator: (value) {
          if (value!.isEmpty) {
            return "Please enter a title";
          }
        },
        onSaved: (newValue) => recipe.title = newValue,
      ),
      TextFormField(
        keyboardType: TextInputType.number,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          hintText: "Time (minutes)",
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue.shade400,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              )),
        ),
        textAlign: TextAlign.center,
        validator: (value) {
          if (value!.isEmpty) {
            return "Please enter a time";
          }
        },
        onSaved: (newValue) => recipe.time = num.tryParse(newValue!),
      ),
      TextFormField(
        keyboardType: TextInputType.number,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          hintText: "Servings",
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue.shade400,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              )),
        ),
        textAlign: TextAlign.center,
        validator: (value) {
          if (value!.isEmpty) {
            return "Please enter the number of servings";
          }
        },
        onSaved: (newValue) =>
            recipe.yeild = "${num.tryParse(newValue!)} Servings",
      ),
      const Text(
        "Ingredients",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.black, fontFamily: "LobsterTwo", fontSize: 16),
      ),
      customIngredientTextFormField(),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizeTransition(
                sizeFactor: _animationAddIngredient!,
                axis: Axis.horizontal,
                child: SizedBox(
                    width: 300,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue[400]),
                        onPressed: () {
                          setState(() {
                            if (ingredientsIndex == 7) {
                              toggleButtonsIngredient();
                            }
                            formWidgets.insert(ingredientsIndex,
                                customIngredientTextFormField());
                            ingredientsIndex++;
                            instructionsIndex++;
                          });
                        },
                        child: const Icon(Icons.add_circle_outline_rounded))))),
        SizeTransition(
            sizeFactor: _animationRemoveIngredient!,
            axis: Axis.horizontal,
            axisAlignment: 1,
            child: SizedBox(
                width: 150,
                child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (ingredientsIndex == 8) {
                          toggleButtonsIngredient();
                        }
                        formWidgets.removeAt(ingredientsIndex - 1);
                        ingredientsIndex--;
                        instructionsIndex--;
                      });
                    },
                    child: const Icon(Icons.remove_circle_outline_rounded)))),
      ]),
      const Text(
        "Instructions",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.black, fontFamily: "LobsterTwo", fontSize: 16),
      ),
      customInstructionTextFormField(),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizeTransition(
                sizeFactor: _animationAddInstruction!,
                axis: Axis.horizontal,
                child: SizedBox(
                    width: 300,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue[400]),
                        onPressed: () {
                          setState(() {
                            if (instructionsIndex == ingredientsIndex + 3) {
                              toggleButtonsInstruction();
                            }
                            formWidgets.insert(instructionsIndex,
                                customIngredientTextFormField());
                            instructionsIndex++;
                          });
                        },
                        child: const Icon(Icons.add_circle_outline_rounded))))),
        SizeTransition(
            sizeFactor: _animationRemoveInstruction!,
            axis: Axis.horizontal,
            axisAlignment: 1,
            child: SizedBox(
                width: 150,
                child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (instructionsIndex == ingredientsIndex + 4) {
                          toggleButtonsInstruction();
                        }
                        formWidgets.removeAt(instructionsIndex - 1);
                        instructionsIndex--;
                      });
                    },
                    child: const Icon(Icons.remove_circle_outline_rounded)))),
      ]),
      ImagePickerWidget(setImage),
      ElevatedButton(
        onPressed: () async {
          final form = formKey.currentState!;
          if (form.validate()) {
            form.save();
            String? username = await storage.read(key: 'username');
            recipe.author = username;
            recipe.url =
                "foodie/${recipe.author}/${recipe.title!.replaceAll(' ', '-')}";
            recipe.image = await uploadImage();

            final request = await http.post(
                Uri.parse("http://10.0.2.2:8888/recipe/"),
                headers: <String, String>{'Content-Type': 'application/json'},
                body: jsonEncode(recipe.toJson()));

            print(request.statusCode);

            if (request.statusCode == 200) {
              Map<String, dynamic> data = jsonDecode(request.body);
              print(data);

              final response = await http.put(
                  Uri.parse("http://10.0.2.2:8888/userrecipes/my/$username"),
                  headers: <String, String>{'Content-Type': 'application/json'},
                  body: jsonEncode(recipe.url));

              await _controllerCheck!.forward();
              await _controllerCheck!
                  .animateBack(0, duration: const Duration(milliseconds: 1000));

              widget.notifyParent();
            }
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
        child: const Text(
          "Add Recipe",
          style: TextStyle(color: Colors.black),
        ),
      ),
    ]);
  }

  _AddRecipePage();

  Future<String> uploadImage() async {
    var minio = Minio(
        endPoint: "s3.amazonaws.com",
        accessKey: getAccessKey(),
        secretKey: getsecretKey(),
        region: "us-west-2");

    var path = "images/${image!.name}";

    await minio
        .fPutObject("fooodie", path, image!.path, {'x-amz-acl': 'public-read'});

    return "https://fooodie.s3.us-west-2.amazonaws.com/$path";
  }

  Widget customInstructionTextFormField() {
    return TextFormField(
        minLines: 1,
        maxLines: 10000,
        //expands: true,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          //hintText: "Title",
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue.shade400,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              )),
          //suffix: IconButton(onPressed: (){}, icon: Icon(Icons.remove_circle_outline_rounded))
        ),
        textAlign: TextAlign.center,
        validator: (value) {
          if (value!.isEmpty) {
            return "Please enter an instruction";
          }
        },
        onSaved: (newValue) => recipe.instructions!.add(newValue!));
  }

  Widget customIngredientTextFormField() {
    return TextFormField(
        minLines: 1,
        maxLines: 10000,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          //hintText: "Title",
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue.shade400,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              )),
          //suffix: IconButton(onPressed: (){}, icon: Icon(Icons.remove_circle_outline_rounded))
        ),
        textAlign: TextAlign.center,
        validator: (value) {
          if (value!.isEmpty) {
            return "Please enter an ingredient";
          }
        },
        onSaved: (newValue) => recipe.ingredients!.add(newValue!));
  }

  void toggleButtonsIngredient() {
    if (_animationAddIngredient!.status != AnimationStatus.completed) {
      _controllerAddIngredient!.forward();
      _controllerRemoveIngredient!
          .animateBack(0, duration: Duration(milliseconds: 500));
    } else {
      _controllerAddIngredient!
          .animateBack(0, duration: Duration(milliseconds: 500));
      _controllerRemoveIngredient!.forward();
    }
  }

  void toggleButtonsInstruction() {
    if (_animationAddInstruction!.status != AnimationStatus.completed) {
      _controllerAddInstruction!.forward();
      _controllerRemoveInstruction!
          .animateBack(0, duration: Duration(milliseconds: 500));
    } else {
      _controllerAddInstruction!
          .animateBack(0, duration: Duration(milliseconds: 500));
      _controllerRemoveInstruction!.forward();
    }
  }

  void setImage(XFile image) {
    this.image = image;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: FadeIn(
            duration: Duration(milliseconds: 400),
            child: Stack(alignment: Alignment.center, children: [
              Container(
                  width: MediaQuery.of(context).size.width * .9,
                  height: MediaQuery.of(context).size.height * .85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                            height: 5,
                          ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      itemCount: formWidgets.length,
                      itemBuilder: ((context, index) => formWidgets[index]))),
              Center(
                  //alignment: Alignment.center,
                  child: SizeTransition(
                axis: Axis.horizontal,
                axisAlignment: -1,
                sizeFactor: _animationCheck!,
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 410,
                  shadows: [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 30,
                        offset: Offset(0, 2))
                  ],
                ),
              )),
            ])));
  }
}
