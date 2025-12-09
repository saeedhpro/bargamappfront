import 'package:bargam_app/features/home/data/datasources/tool_local_data_source.dart';
import 'package:bargam_app/features/home/data/datasources/tool_remote_data_source.dart';
import 'package:bargam_app/features/home/domain/usecases/get_history_plants.dart';
import 'package:bargam_app/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

// Core & Utils
import 'core/network/http_client.dart';
import 'core/utils/token_manager.dart';

// Auth
import 'features/auth/presentation/providers/auth_provider.dart';

// Home & Plants
import 'features/home/presentation/providers/plant_provider.dart';
import 'features/home/data/repositories/plant_repository_impl.dart';
import 'features/home/data/datasources/plant_remote_data_source.dart';
import 'features/home/data/datasources/plant_local_data_source.dart';
import 'features/home/domain/usecases/get_all_plants.dart';
import 'features/home/domain/usecases/search_plants.dart';
import 'features/home/domain/usecases/get_plant_details.dart';

// Garden
import 'features/garden/presentation/providers/garden_provider.dart';

// Tools
import 'features/tools/presentation/providers/tool_provider.dart';
import 'features/tools/data/repositories/tool_repository_impl.dart';
// اگر هنوز usecase های تولز را کامل نکرده‌اید، این ایمپورت‌ها ممکن است اضافه باشند
// اما طبق کد خودتان نگه داشتم
// import 'features/tools/domain/usecases/get_all_tools.dart';
// import 'features/tools/domain/usecases/search_tools.dart';

// ===> 1. ایمپورت جدید: Subscription Provider <===
import 'features/subscription/presentation/providers/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('plants');
  await Hive.openBox('gardens');
  await Hive.openBox('tools');

  // Initialize core dependencies
  final tokenManager = await TokenManager.create();

  // تنظیم Base URL
  final httpClient = HttpClient(
    // baseUrl: 'http://65.108.27.190:8001/api/v1',
    baseUrl: 'http://127.0.0.1:8000/api/v1',
    tokenManager: tokenManager,
  );

  // Plant dependencies
  final plantRemoteDataSource = PlantRemoteDataSourceImpl(httpClient: httpClient);
  final plantLocalDataSource = PlantLocalDataSourceImpl();
  final plantRepository = PlantRepositoryImpl(
    remoteDataSource: plantRemoteDataSource,
    localDataSource: plantLocalDataSource,
  );

  // Tools dependencies
  final toolRemoteDataSource = ToolRemoteDataSourceImpl();
  final toolLocalDataSource = ToolLocalDataSourceImpl();
  final toolRepository = ToolRepositoryImpl(
    remoteDataSource: toolRemoteDataSource,
    localDataSource: toolLocalDataSource,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenManager>.value(value: tokenManager),
        Provider<HttpClient>.value(value: httpClient),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            httpClient: httpClient,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            tokenManager: tokenManager,
            httpClient: httpClient,
          ),
        ),

        // ===> 2. اضافه کردن SubscriptionProvider به لیست اصلی <===
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(
            httpClient: httpClient, // همان کلاینت اصلی را به آن می‌دهیم
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => PlantProvider(
            getAllPlants: GetAllPlants(plantRepository),
            searchPlants: SearchPlants(plantRepository),
            getPlantDetails: GetPlantDetails(plantRepository),
            getHistoryPlants: GetHistoryPlants(plantRepository),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => GardenProvider(httpClient: httpClient),
        ),

        ChangeNotifierProvider(
          create: (_) => ToolProvider(httpClient: httpClient),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برگام',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
        ),
        fontFamily: 'Vazir',
        useMaterial3: true,
      ),

      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: child!,
            ),
          ),
        );
      },

      home: const SplashPage(),
    );
  }
}
