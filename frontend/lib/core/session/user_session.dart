class UserSession {
  static int? userId;
  static String? name;
  static String? email;

  static void setUser(Map<String, dynamic> user) {
    userId = user['id'];
    name = user['name'];
    email = user['email'];
  }

  static Map<String, dynamic>? getUser() {
    if (userId == null) return null;

    return {"id": userId, "name": name, "email": email};
  }

  static void clear() {
    userId = null;
    name = null;
    email = null;
  }

  static bool get isLogged => userId != null;
}
