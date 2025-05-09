import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "FlutterTaskManager/providers/user_providers.dart";
import "FlutterTaskManager/providers/task_providers.dart";
import "FlutterTaskManager/screens/login_screen.dart";
import "FlutterTaskManager/screens/task_listscreen.dart";
//import 'package:flutter/material.dart';
//import "userMS/view/UserListScreen.dart";
//import "noteApp/view/NoteListScreen.dart";
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
     ],
      child: MaterialApp(
        title: 'Flutter Task Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Widget giúp điều hướng tự động dựa trên trạng thái đăng nhập
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoggedIn) {
      return TaskListScreen();
    } else {
      return LoginScreen();
    }
  }
}
//void main() {
 //runApp(const MyApp());
//}

//class MyApp extends StatelessWidget {
 // const MyApp({super.key});

  // This widget is the root of your application.
// @override
//  Widget build(BuildContext context) {
 //   return MaterialApp(
 //     title: 'Flutter Demo',
 //     theme: ThemeData(
  //      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  //    ),
 //     home:  NoteListScreen(),
 //   );
 // }
//}
