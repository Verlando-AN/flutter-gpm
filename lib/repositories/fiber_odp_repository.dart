import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/fiber_odp_model.dart';

class FiberOdpRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<FiberOdpModel>> getOdps({int? fiberodcId, String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        '/maps/odps',
        queryParameters: {
          if (fiberodcId != null) 'fiberodc_id': fiberodcId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final List data = response.data['data'] ?? [];

      return data.map((e) => FiberOdpModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengambil data ODP',
      );
    }
  }
}
