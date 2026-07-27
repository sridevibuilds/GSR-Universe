// Dependency Injection Registration Container
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/secure_storage.dart';
import '../network/connectivity_monitor.dart';
import '../network/offline_cache.dart';
import '../network/api_client.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';

import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';

import '../../features/faculty/data/datasources/faculty_remote_data_source.dart';
import '../../features/faculty/domain/repositories/faculty_repository.dart';
import '../../features/faculty/data/repositories/faculty_repository_impl.dart';
import '../../features/faculty/presentation/cubit/faculty_cubit.dart';

import '../../features/parent/data/datasources/parent_remote_data_source.dart';
import '../../features/parent/domain/repositories/parent_repository.dart';
import '../../features/parent/data/repositories/parent_repository_impl.dart';
import '../../features/parent/presentation/cubit/parent_cubit.dart';

final sl = GetIt.instance;

/// Initialize all core dependencies on application startup
Future<void> init() async {
  // 1. External Third-party plugins
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<Dio>(() => Dio());

  // 2. Core Service Wrappers
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage(sl()));
  sl.registerLazySingleton<ConnectivityMonitor>(() => ConnectivityMonitor(sl()));
  sl.registerLazySingleton<OfflineCache>(() => OfflineCache(sl()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl(), sl()));

  // 3. Auth Feature Layers Mappings
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    remoteDataSource: sl(),
    secureStorage: sl(),
  ));

  // 4. Admin Feature Layers Mappings
  sl.registerLazySingleton<AdminRemoteDataSource>(() => AdminRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(remoteDataSource: sl()));

  // 5. Faculty Feature Layers Mappings
  sl.registerLazySingleton<FacultyRemoteDataSource>(() => FacultyRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<FacultyRepository>(() => FacultyRepositoryImpl(remoteDataSource: sl()));

  // 6. Parent Feature Layers Mappings
  sl.registerLazySingleton<ParentRemoteDataSource>(() => ParentRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ParentRepository>(() => ParentRepositoryImpl(remoteDataSource: sl()));

  // 7. Features Controllers / Blocs
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
  sl.registerFactory<LoginCubit>(() => LoginCubit(sl()));
  sl.registerFactory<AdminCubit>(() => AdminCubit(sl()));
  sl.registerFactory<FacultyCubit>(() => FacultyCubit(sl()));
  sl.registerFactory<ParentCubit>(() => ParentCubit(sl()));
}
