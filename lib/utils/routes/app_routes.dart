import 'package:flutter/material.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/views/edit_profile_view.dart';
import 'package:talkie/views/home_view.dart';
import 'package:talkie/views/nav_bar.dart';
import 'package:talkie/views/photo_view.dart';
import 'package:talkie/views/profile_view.dart';
import 'package:talkie/views/search_view.dart';
import 'package:talkie/views/sign_up_view.dart';
import 'package:talkie/views/splash_view.dart';

import '../../models/user_model.dart';
import '../../views/login_view.dart';
import '../../views/chat_view.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(builder: (context) => const HomeView());

      case RouteNames.chatView:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final chatId = args['chatId'] as String;
          final userModel = args['userModel'] as UserModel;
          return MaterialPageRoute(
            builder: (context) =>
                ChatView(userModel: userModel, chatId: chatId),
          );
        }
        return _errorRoute(settings.name);
      case RouteNames.login:
        return MaterialPageRoute(builder: (context) => const LoginView());
      case RouteNames.signUp:
        return MaterialPageRoute(builder: (context) => const SignUpView());
      case RouteNames.splashView:
        return MaterialPageRoute(builder: (context) => const SplashView());
      case RouteNames.searchView:
        return MaterialPageRoute(builder: (context) => const SearchView());
      case RouteNames.photoView:
        if (settings.arguments is String) {
          final args = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => PhotoView(imageUrl: args),
          );
        }
        return _errorRoute(settings.name);
      case RouteNames.navBar:
        return MaterialPageRoute(builder: (context) => NavBar());
      case RouteNames.profileView:
        return MaterialPageRoute(builder: (context) => ProfileView());
      case RouteNames.editProfileView:
        return MaterialPageRoute(builder: (context) => EditProfileView());
      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (context) =>
          Scaffold(body: Center(child: Text("No route found for $routeName"))),
    );
  }
}
