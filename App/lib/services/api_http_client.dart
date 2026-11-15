import 'dart:async';

import 'package:http/http.dart' as http;

import 'network_status_service.dart';

class ApiTimeoutException implements Exception {
  const ApiTimeoutException(this.timeout);

  final Duration timeout;

  @override
  String toString() =>
      'La conexión tardó demasiado. Revisa tu internet e intenta nuevamente.';
}

class ApiRequestCancelledException implements Exception {
  const ApiRequestCancelledException();

  @override
  String toString() => 'La solicitud fue reemplazada por una más reciente.';
}

class ApiHttpClient extends http.BaseClient {
  ApiHttpClient({
    http.Client? inner,
    this.requestTimeout = const Duration(seconds: 15),
    this.maxReadRetries = 1,
    this.retryDelay = const Duration(milliseconds: 400),
  }) : _inner = inner ?? http.Client();

  static const latestRequestKeyHeader = 'x-tinku-latest-request-key';
  static const timeoutSecondsHeader = 'x-tinku-timeout-seconds';

  static const _retryableMethods = {'GET', 'HEAD', 'OPTIONS'};
  static const _retryableStatuses = {408, 425, 429, 500, 502, 503, 504};

  final http.Client _inner;
  final Duration requestTimeout;
  final int maxReadRetries;
  final Duration retryDelay;
  final Map<String, _RequestOperation> _latestRequests = {};
  bool _closed = false;

  void cancelLatestRequest(String key) {
    _latestRequests.remove(key)?.cancel();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) {
      throw StateError('ApiHttpClient is already closed');
    }

    final requestData = _RequestData.from(request);
    final operation = _RequestOperation();
    final latestKey = requestData.latestRequestKey;

    if (latestKey != null) {
      cancelLatestRequest(latestKey);
      _latestRequests[latestKey] = operation;
    }

    try {
      final canRetry =
          requestData.canClone && _retryableMethods.contains(request.method);
      final attempts = canRetry ? maxReadRetries + 1 : 1;

      for (var attempt = 0; attempt < attempts; attempt++) {
        operation.throwIfCancelled();

        try {
          final response = await _sendAttempt(
            requestData.createRequest(operation.abortFuture),
            operation,
            requestData.timeout ?? requestTimeout,
          );
          NetworkStatusService.instance.reportRequestSucceeded();

          final shouldRetry = attempt + 1 < attempts &&
              _retryableStatuses.contains(response.statusCode);
          if (!shouldRetry) return response;
        } on ApiRequestCancelledException {
          rethrow;
        } catch (_) {
          if (attempt + 1 >= attempts) rethrow;
        }

        await _waitBeforeRetry(operation);
      }

      throw StateError('Request attempts exhausted');
    } catch (error) {
      if (_looksLikeConnectivityFailure(error)) {
        unawaited(NetworkStatusService.instance.refresh());
      }
      rethrow;
    } finally {
      if (latestKey != null &&
          identical(_latestRequests[latestKey], operation)) {
        _latestRequests.remove(latestKey);
      }
    }
  }

  bool _looksLikeConnectivityFailure(Object error) {
    if (error is http.ClientException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable');
  }

  Future<http.StreamedResponse> _sendAttempt(
    http.BaseRequest request,
    _RequestOperation operation,
    Duration timeout,
  ) async {
    final networkRequest = () async {
      final response = await _inner.send(request);
      final bytes = await response.stream.toBytes();

      return http.StreamedResponse(
        Stream<List<int>>.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    }();

    try {
      return await Future.any([
        networkRequest,
        operation.cancelledFuture.then<http.StreamedResponse>((_) {
          throw const ApiRequestCancelledException();
        }),
      ]).timeout(
        timeout,
        onTimeout: () {
          operation.abortCurrentAttempt();
          throw ApiTimeoutException(timeout);
        },
      );
    } catch (_) {
      operation.throwIfCancelled();
      rethrow;
    } finally {
      operation.finishAttempt();
    }
  }

  Future<void> _waitBeforeRetry(_RequestOperation operation) async {
    await Future.any([
      Future<void>.delayed(retryDelay),
      operation.cancelledFuture.then<void>((_) {
        throw const ApiRequestCancelledException();
      }),
    ]);
    operation.throwIfCancelled();
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;

    for (final operation in _latestRequests.values) {
      operation.cancel();
    }
    _latestRequests.clear();
    _inner.close();
  }
}

class _RequestOperation {
  final Completer<void> _cancelled = Completer<void>();
  Completer<void>? _activeAbort;

  Future<void> get cancelledFuture => _cancelled.future;

  Future<void> get abortFuture {
    final abort = Completer<void>();
    _activeAbort = abort;
    return abort.future;
  }

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
    abortCurrentAttempt();
  }

  void abortCurrentAttempt() {
    final abort = _activeAbort;
    if (abort != null && !abort.isCompleted) abort.complete();
  }

  void finishAttempt() {
    _activeAbort = null;
  }

  void throwIfCancelled() {
    if (_cancelled.isCompleted) {
      throw const ApiRequestCancelledException();
    }
  }
}

class _RequestData {
  _RequestData({
    required this.original,
    required this.headers,
    required this.latestRequestKey,
    required this.timeout,
  });

  factory _RequestData.from(http.BaseRequest request) {
    final headers = Map<String, String>.from(request.headers);
    final latestRequestKey =
        headers.remove(ApiHttpClient.latestRequestKeyHeader);
    final timeoutValue = headers.remove(ApiHttpClient.timeoutSecondsHeader);
    final timeoutSeconds = int.tryParse(timeoutValue ?? '');

    return _RequestData(
      original: request,
      headers: headers,
      latestRequestKey:
          latestRequestKey?.trim().isEmpty == true ? null : latestRequestKey,
      timeout: timeoutSeconds != null && timeoutSeconds > 0
          ? Duration(seconds: timeoutSeconds)
          : null,
    );
  }

  final http.BaseRequest original;
  final Map<String, String> headers;
  final String? latestRequestKey;
  final Duration? timeout;

  bool get canClone => original is http.Request;

  http.BaseRequest createRequest(Future<void> abortTrigger) {
    final request = original;

    if (request is http.Request) {
      return http.AbortableRequest(
        request.method,
        request.url,
        abortTrigger: abortTrigger,
      )
        ..headers.addAll(headers)
        ..bodyBytes = request.bodyBytes
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    }

    if (request is http.MultipartRequest) {
      return http.AbortableMultipartRequest(
        request.method,
        request.url,
        abortTrigger: abortTrigger,
      )
        ..headers.addAll(headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    }

    request.headers
      ..clear()
      ..addAll(headers);
    return request;
  }
}
