class Recipe {
  String? url;
  String? title;
  String? author;
  num? time;
  String? yeild;
  List<String>? ingredients = [];
  List<String>? instructions = [];
  String? image;
  Recipe(
      {this.url,
      this.title,
      this.author,
      this.time,
      this.yeild,
      this.ingredients,
      this.instructions,
      this.image});

  Recipe.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    title = json['title'];
    author = json['author'];
    time = json['time'];
    yeild = json['yeild'];
    ingredients = json['ingredients'].cast<String>();
    instructions = json['instructions'].cast<String>();
    image = json['image'];
  }

    Recipe.fromJsonSearch(Map<String, dynamic> json) {
    url = json['Url'];
    title = json['Title'];
    author = json['Author'];
    time = json['Time'];
    yeild = json['Yeild'];
    ingredients = json['Ingredients'].cast<String>();
    instructions = json['Instructions'].cast<String>();
    image = json['Image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Url'] = this.url;
    data['Title'] = this.title;
    data['Author'] = this.author;
    data['Time'] = this.time;
    data['Yeild'] = this.yeild;
    data['Ingredients'] = this.ingredients;
    data['Instructions'] = this.instructions;
    data['Image'] = this.image;
    return data;
  }
}
