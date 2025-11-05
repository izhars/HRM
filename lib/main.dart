import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staffsync/widgets/app_entry.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: MaterialApp(
        title: 'Employee Management',
        theme: appTheme,
        home: AppEntry(), // <-- use AppEntry here
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
