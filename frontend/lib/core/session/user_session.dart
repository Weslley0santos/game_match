class UserSession {
  static int? userId;
  static String? name;
  static String? username;
  static String? accessToken;

  static void setUser(Map<String, dynamic> user) {
    userId = user['id'];
    name = user['name'];
    username = user['username'];
    accessToken = user['accessToken'];
  }

  static Map<String, dynamic>? getUser() {
    if (userId == null) return null;

    return {"id": userId, "name": name, "username": username};
  }

  static void clear() {
    userId = null;
    name = null;
    username = null;
    accessToken = null;
  }

  static bool get isLogged => userId != null;
}
