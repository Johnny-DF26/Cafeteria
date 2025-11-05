import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes.dart';

// Screens
import 'screens/choose/choose_profile_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/signup_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/login/reset_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/favorites/favorites.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/order/order_screen.dart';

// Admin
import 'screens/admin/admin_screen.dart';
import 'screens/admin/login_admin_screen.dart';
import 'screens/admin/userManagement/user_management_screen.dart';

// Provider
import 'screens/global/user_provider.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalConfig.GlobalConfig.useOnline = true; // Conecatar ao servidor local ou online



  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cafeteria App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(121, 85, 72, 1),
        ),
        useMaterial3: true,
      ),
      initialRoute: Routes.choose,
      onGenerateRoute: (settings) {
        switch (settings.name) {

          // Acesso ao sistema
          case Routes.choose:
            return MaterialPageRoute(builder: (_) => const ChooseProfileScreen());
          case Routes.signup:
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case Routes.forgotPassword:
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case Routes.resetPassword:
            return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());

          // Admin
          case Routes.loginAdmin:
            return MaterialPageRoute(builder: (_) => const LoginAdminScreen());
          case Routes.admin:
            final adminData = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(builder: (_) => AdminScreen(adminData: adminData));
          case Routes.userManagement:
            final adminData = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(builder: (_) => UserManagementScreen(adminData: adminData));

          // Usuário
          case Routes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case Routes.home:
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case Routes.favorites:
            return MaterialPageRoute(builder: (_) => const FavoriteScreen());
          case Routes.cart:
            return MaterialPageRoute(builder: (_) => const CartScreen());
          case Routes.profile:
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case Routes.payment:
            return MaterialPageRoute(builder: (_) => const PaymentScreen());
          case Routes.order:
           return MaterialPageRoute(builder: (_) => const OrderScreen());

          default:
            return MaterialPageRoute(builder: (_) => const ChooseProfileScreen());
        }
      },
    );
  }
}
