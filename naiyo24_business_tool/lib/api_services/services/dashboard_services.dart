import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/dashboard_stats_model.dart';

class DashboardService {
  static Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final url = Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.dashboardStats}');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardStatsModel.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }
}
