import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';

class WhatsAppService {
  final String baseUrl;
  final Dio _dio;
  io.Socket? _socket;

  WhatsAppService({this.baseUrl = 'http://localhost:3000'})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  /// Initialize real-time connection for an academy
  void connectToLiveUpdates(String academyId, {
    Function(String)? onQrReceived,
    Function(String)? onStatusChanged,
  }) {
    _socket?.disconnect();
    
    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .build());

    _socket!.onConnect((_) => debugPrint('Connected to WhatsApp Backend Socket'));
    
    _socket!.on('qr-$academyId', (data) {
      if (data['qr'] != null) {
        onQrReceived?.call(data['qr']);
      }
    });

    _socket!.on('status-$academyId', (data) {
      if (data['status'] != null) {
        onStatusChanged?.call(data['status']);
      }
    });
  }

  void disconnectLiveUpdates() {
    _socket?.disconnect();
    _socket = null;
  }

  /// REST: Trigger QR generation
  Future<Map<String, dynamic>> connect(String academyId) async {
    try {
      final response = await _dio.post('/connect', data: {'academyId': academyId});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// REST: Get current status
  Future<Map<String, dynamic>> getStatus(String academyId) async {
    try {
      final response = await _dio.get('/status/$academyId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// REST: Send single message
  Future<bool> sendMessage({
    required String academyId,
    required String to,
    required String message,
  }) async {
    try {
      final response = await _dio.post('/send-message', data: {
        'academyId': academyId,
        'to': to,
        'message': message,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// REST: Send bulk messages
  Future<List<dynamic>> sendBulk({
    required String academyId,
    required List<Map<String, String>> messages,
  }) async {
    try {
      final response = await _dio.post('/send-bulk', data: {
        'academyId': academyId,
        'messages': messages,
      });
      return response.data['results'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// REST: Disconnect/Logout
  Future<bool> disconnect(String academyId) async {
    try {
      final response = await _dio.post('/disconnect', data: {'academyId': academyId});
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
