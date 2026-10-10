import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kiro/app/providers/locale_provider.dart';
import 'package:kiro/core/services/socket_service.dart';

import '../services/device_id_service.dart';
import '../storage/secure_storage_service.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../core/exceptions/api_exception.dart';
import 'api_client.dart';
import 'api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final AuthRepository _authRepository;

  // =========================================================
  // 🔄 REFRESH LOCK
  // =========================================================
  //
  // يوجد refresh واحد فقط في نفس الوقت.
  //
  // إذا حصلت عدة Requests على 401 في نفس اللحظة،
  // فإنها جميعًا تنتظر نفس عملية refresh.
  //
  Completer<String>? _refreshCompleter;

  AuthInterceptor({required this._storage, required this._authRepository});

  // =========================================================
  // 📤 REQUEST
  // =========================================================

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // =====================================================
      // 🔐 ACCESS TOKEN
      // =====================================================

      final accessToken = await _storage.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      // =====================================================
      // 🌍 LANGUAGE
      // =====================================================

      final language = await LocaleNotifier().getLocale();

      options.headers['x-lang'] = language ?? 'en';

      handler.next(options);
    } catch (_) {
      // =====================================================
      // ⚠️ إذا فشل الوصول إلى Storage
      // لا نسقط الطلب.
      // =====================================================

      handler.next(options);
    }
  }

  // =========================================================
  // ❌ ERROR
  // =========================================================

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // =======================================================
    // ❌ ليس 401
    // =======================================================

    if (statusCode != 401) {
      return handler.next(err);
    }

    // =======================================================
    // 🚫 منع Refresh على Refresh Endpoint نفسه
    // =======================================================

    if (_isRefreshRequest(err.requestOptions)) {
      return handler.next(err);
    }

    // =======================================================
    // 🚫 منع Retry Loop
    // =======================================================
    //
    // إذا قمنا بإعادة الطلب بعد refresh
    // ثم رجع 401 مرة أخرى، لا نحاول refresh إلى ما لا نهاية.
    //

    final alreadyRetried = err.requestOptions.extra['auth_retry'] == true;

    if (alreadyRetried) {
      return handler.next(err);
    }

    try {
      // =====================================================
      // 🔄 الحصول على Access Token جديد
      // =====================================================

      final newAccessToken = await _getValidAccessToken();

      // =====================================================
      // 🔁 إعادة الطلب الأصلي
      // =====================================================

      final requestOptions = err.requestOptions;

      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      // =====================================================
      // 🛡️ تسجيل أن هذا الطلب تمت إعادة محاولته
      // =====================================================

      requestOptions.extra['auth_retry'] = true;

      final response = await ApiClient.dio.fetch(requestOptions);

      return handler.resolve(response);
    } catch (e) {
      // =====================================================
      // ⚠️ مهم جدًا
      //
      // لا نحذف Tokens هنا بشكل عشوائي.
      //
      // سيتم حذفها فقط إذا كان Backend قال فعلاً
      // إن Refresh Token غير صالح.
      // =====================================================

      if (_isRefreshTokenInvalidError(e)) {
        await _clearTokensSafely();
      }

      // =====================================================
      // ❌ نرجع الخطأ الأصلي
      // =====================================================

      return handler.next(err);
    }
  }

  // =========================================================
  // 🔐 GET VALID ACCESS TOKEN
  // =========================================================

  Future<String> _getValidAccessToken() async {
    // =======================================================
    // 🔄 يوجد Refresh شغال بالفعل
    // =======================================================
    //
    // أي Request آخر ينتظر نفس العملية.
    //

    final existingCompleter = _refreshCompleter;

    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    // =======================================================
    // 🔒 إنشاء Refresh جديد
    // =======================================================

    final completer = Completer<String>();

    _refreshCompleter = completer;

    try {
      // =====================================================
      // 🔑 قراءة Refresh Token
      // =====================================================

      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw const ApiException(
          code: 'REFRESH_TOKEN_MISSING',
          message: 'Refresh token is missing',
        );
      }

      // =====================================================
      // 📱 Device ID
      // =====================================================

      final deviceId = await DeviceIdService.getDeviceId();

      // =====================================================
      // 🔄 REFRESH TOKEN
      // =====================================================

      final response = await _authRepository.refreshToken(
        refreshToken: refreshToken,
        deviceFingerprint: deviceId,
      );

      // =====================================================
      // 💾 حفظ الـ Tokens الجديدة
      // =====================================================

      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // =====================================================
      // 🔌 تحديث Socket بالـ Access Token الجديد
      // =====================================================

      SocketService.instance.updateAccessToken(response.accessToken);

      // =====================================================
      // ✅ نجاح
      // =====================================================

      if (!completer.isCompleted) {
        completer.complete(response.accessToken);
      }

      return response.accessToken;
    } catch (e, stackTrace) {
      // =====================================================
      // ❌ Refresh فشل
      // =====================================================
      //
      // لا نحذف Tokens هنا.
      //
      // السبب قد يكون:
      //
      // - Render نائم
      // - Server unavailable
      // - Timeout
      // - Internet problem
      // - Temporary backend error
      //
      // الحذف يتم فقط في onError عندما نعرف
      // أن الخطأ صراحةً متعلق بصلاحية Refresh Token.
      // =====================================================

      if (!completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }

      rethrow;
    } finally {
      // =====================================================
      // 🔓 فتح Refresh Lock
      // =====================================================

      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  // =========================================================
  // 🔍 CHECK REFRESH REQUEST
  // =========================================================

  bool _isRefreshRequest(RequestOptions options) {
    return options.path == ApiConstants.refreshToken;
  }

  // =========================================================
  // 🔐 CHECK REFRESH TOKEN INVALID
  // =========================================================
  //
  // هنا فقط نقرر هل يجب مسح Tokens أم لا.
  //
  // ⚠️ يجب أن تتطابق هذه الأكواد مع الأكواد التي
  // يرجعها Backend عند رفض Refresh Token.
  //

  bool _isRefreshTokenInvalidError(Object error) {
    if (error is! ApiException) {
      return false;
    }

    const clearTokenErrorCodes = {
      'INVALID_REFRESH_TOKEN',
      'REFRESH_TOKEN_REVOKED',
      'REFRESH_TOKEN_EXPIRED',
      'DEVICE_MISMATCH',
      'PASSWORD_CHANGED',
    };

    return clearTokenErrorCodes.contains(error.code);
  }

  // =========================================================
  // 🧹 CLEAR TOKENS SAFELY
  // =========================================================

  Future<void> _clearTokensSafely() async {
    try {
      await _storage.clearTokens();
    } catch (_) {
      // =====================================================
      // لا نسمح لخطأ SecureStorage
      // بإسقاط الـ Interceptor.
      // =====================================================
    }
  }
}
