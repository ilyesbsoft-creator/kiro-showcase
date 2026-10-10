import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiro/shared/repositories/auth_repository.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/network/auth_interceptor.dart';
import 'core/storage/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDio();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: KiroApp()));
}

void setupDio() {
 // ApiClient.dio.interceptors.clear();

  ApiClient.dio.interceptors.add(
    AuthInterceptor(
      storage: SecureStorageService.instance,
      authRepository: AuthRepository(),
    ),
  );
}
