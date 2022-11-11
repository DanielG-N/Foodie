import 'package:flutter/material.dart';
import 'package:foodie/ImagePicker.dart';
import 'package:foodie/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePage();
}

class _AddRecipePage extends State<AddRecipePage> {
  Recipe recipe = Recipe();
  final formKey = GlobalKey<FormState>();
  int ingredientsIndex = 4;
  int instructionsIndex = 8;
  List<Widget> formWidgets = [];

  _AddRecipePage() {
    formWidgets.addAll([
      TextFormField(
        decoration: const InputDecoration(
          hintText: "Title",
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Please enter a title";
          }
        },
        onSaved: (newValue) => recipe.title = newValue,
      ),
      TextFormField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(backgroundColor: Colors.white),
          hintText: "Time minutes",
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Please input a time";
          }
        },
        onSaved: (newValue) => recipe.time = num.tryParse(newValue!),
      ),
      TextFormField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(backgroundColor: Colors.white),
          hintText: "Servings",
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Please input the number of servings";
          }
        },
        onSaved: (newValue) => recipe.yeild = "$newValue Servings",
      ),
      const Text(
        "Ingredients",
        style: TextStyle(color: Colors.white),
      ),
      TextFormField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(backgroundColor: Colors.white),
          //hintText: "Ingredients",
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Please input an ingedient";
          }
        },
        onSaved: (newValue) => recipe.ingredients!.add(newValue!),
      ),
      ElevatedButton(
          onPressed: () {
            setState(() {
              formWidgets.insert(
                ingredientsIndex,
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(backgroundColor: Colors.white),
                    //hintText: "Ingredients",
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please input an ingredient";
                    }
                  },
                  onSaved: (newValue) => recipe.ingredients!.add(newValue!),
                ),
              );
              ingredientsIndex++;
              instructionsIndex++;
            });
          },
          child: const Icon(Icons.add_circle_outline_rounded)),
      const Text(
        "Instructions",
        style: TextStyle(color: Colors.white),
      ),
      TextFormField(
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(backgroundColor: Colors.white),
          //hintText: "Ingredients",
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Please input an instruction";
          }
        },
        onSaved: (newValue) => recipe.instructions!.add(newValue!),
      ),
      ElevatedButton(
          onPressed: () {
            setState(() {
              addItem(
                  TextFormField(
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(backgroundColor: Colors.white),
                      //hintText: "Ingredients",
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please input an instruction";
                      }
                    },
                    onSaved: (newValue) => recipe.instructions!.add(newValue!),
                  ),
                  instructionsIndex);
            });
            instructionsIndex++;
          },
          child: const Icon(Icons.add_circle_outline_rounded)),
      ImagePickerWidget(),
      ElevatedButton(
        onPressed: () async {
          final form = formKey.currentState!;
          if (form.validate()) {
            form.save();

            final request = await http.post(
                Uri.parse("http://10.0.2.2:9005/user/login"),
                headers: <String, String>{'Content-Type': 'application/json'},
                body: jsonEncode(recipe.toJson()));

            if (request.statusCode == 200) {
              Map<String, dynamic> data = jsonDecode(request.body);
            }
          }
          setState(() {
            //////////////////////////////////////////
          });
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
        child: const Text(
          "Add Recipe",
          style: TextStyle(color: Colors.black),
        ),
      ),
    ]);
  }

  void addItem(Widget item, int index) {
    print(item);
    formWidgets.insert(index, item);
    print(formWidgets);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: ListView.builder(itemCount: formWidgets.length, itemBuilder: ((context, index) => formWidgets[index])));
  }
}
