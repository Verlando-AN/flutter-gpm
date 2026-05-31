import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/ticket_detail_model.dart';
import '../repositories/auth_repository.dart';

class TicketService {
  // Emulator Android Studio:
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // HP fisik:
  static const String baseUrl = 'http://192.168.43.126:8000/api';

  // ===========================================================================
  // GET DETAIL TICKET
  // ===========================================================================

  static Future<TicketDetailResponse> getTicketDetail({
    required int ticketId,
    String? token,
  }) async {
    try {
      final authToken = token?.trim().isNotEmpty == true
          ? token!.trim()
          : await AuthRepository().getToken();

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final normalizedToken = authToken.startsWith('Bearer ')
          ? authToken
          : 'Bearer $authToken';

      final url = Uri.parse('$baseUrl/tickets/$ticketId');

      print('REQUEST URL => $url');
      print('AUTH TOKEN => $normalizedToken');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': normalizedToken,
        },
      );

      print('STATUS CODE => ${response.statusCode}');
      print('BODY => ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);

          if (jsonData['success'] != true) {
            final message =
                jsonData['message']?.toString() ??
                'Gagal mengambil detail ticket.';
            throw Exception(message);
          }

          final detail = TicketDetailResponse.fromJson(jsonData);

          print('DETAIL SUCCESS => ${detail.message}');

          return detail;
        } catch (e, stack) {
          print('PARSE ERROR => $e');
          print(stack);

          throw Exception('Gagal parsing detail ticket: $e');
        }
      }

      String responseMessage = 'Gagal mengambil detail ticket';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map<String, dynamic>) {
          responseMessage =
              errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              responseMessage;
        }
      } catch (_) {}

      throw Exception('$responseMessage (Status: ${response.statusCode})');
    } on SocketException catch (e, stack) {
      print('SERVICE ERROR => $e');
      print(stack);
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on FormatException catch (e, stack) {
      print('PARSE ERROR => $e');
      print(stack);
      throw Exception('Gagal memproses data detail ticket.');
    } catch (e, stack) {
      print('SERVICE ERROR => $e');
      print(stack);
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat mengambil detail ticket');
    }
  }

  // ===========================================================================
  // ASSIGN TICKET
  // ===========================================================================

  static Future<Map<String, dynamic>> assignTicket({
    required int ticketId,
    required int userId,
    required String status,
    required String notes,
    String? acceptedAt,
    String? startedAt,
    String? completedAt,
    File? photoProof,
    String? token,
  }) async {
    try {
      final authToken = token?.trim().isNotEmpty == true
          ? token!.trim()
          : await AuthRepository().getToken();

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Token tidak ditemukan.');
      }

      final normalizedToken = authToken.startsWith('Bearer ')
          ? authToken
          : 'Bearer $authToken';

      final url = Uri.parse('$baseUrl/tickets/$ticketId/assign');

      print('ASSIGN URL => $url');

      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': normalizedToken,
      });

      request.fields['user_id'] = userId.toString();
      request.fields['status'] = status;
      request.fields['notes'] = notes;

      if (acceptedAt != null && acceptedAt.isNotEmpty) {
        request.fields['accepted_at'] = acceptedAt;
      }

      if (startedAt != null && startedAt.isNotEmpty) {
        request.fields['started_at'] = startedAt;
      }

      if (completedAt != null && completedAt.isNotEmpty) {
        request.fields['completed_at'] = completedAt;
      }

      if (photoProof != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo_proof', photoProof.path),
        );
      }

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print('ASSIGN STATUS => ${response.statusCode}');
      print('ASSIGN BODY => ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      throw Exception(data['message'] ?? 'Gagal assign ticket');
    } catch (e, stack) {
      print('ASSIGN ERROR => $e');
      print(stack);

      throw Exception('Terjadi kesalahan saat assign ticket');
    }
  }

  // ===========================================================================
  // COMPLETE TICKET
  // ===========================================================================

  static Future<Map<String, dynamic>> completeTicket({
    required int ticketId,
    required String notes,
    String? completedAt,
    File? photoProof,
    String? token,
  }) async {
    try {
      final authToken = token?.trim().isNotEmpty == true
          ? token!.trim()
          : await AuthRepository().getToken();

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Token tidak ditemukan.');
      }

      final normalizedToken = authToken.startsWith('Bearer ')
          ? authToken
          : 'Bearer $authToken';

      final url = Uri.parse('$baseUrl/tickets/$ticketId/completed');

      print('COMPLETE URL => $url');

      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': normalizedToken,
      });

      request.fields['notes'] = notes;

      if (completedAt != null && completedAt.isNotEmpty) {
        request.fields['completed_at'] = completedAt;
      }

      if (photoProof != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo_proof', photoProof.path),
        );
      }

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print('COMPLETE STATUS => ${response.statusCode}');
      print('COMPLETE BODY => ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      throw Exception(data['message'] ?? 'Gagal menyelesaikan ticket');
    } catch (e, stack) {
      print('COMPLETE ERROR => $e');
      print(stack);

      throw Exception('Terjadi kesalahan saat menyelesaikan ticket');
    }
  }
}
