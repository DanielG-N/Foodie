class User {
  String? Email;
  String? Username;
  String? Password;
  User(
      {
      this.Email,
      this.Username,
      this.Password,
      });

  User.fromJson(Map<String, dynamic> json) {
    Email = json['email'];
    Username = json['username'];
    Password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Email'] = this.Email;
    data['Username'] = this.Username;
    data['Password'] = this.Password;
    return data;
  }
}
