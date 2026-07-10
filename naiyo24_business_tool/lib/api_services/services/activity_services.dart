import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/activity_model.dart';

class ActivityService {
  static Future<List<ActivityModel>> getActivities({int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.activityList}?limit=$limit&offset=$offset'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> activitiesJson = data['data'] as List;
        return activitiesJson.map((json) => ActivityModel.fromJson(json)).toList();
      } else {
        final errorBody = response.body;
        throw Exception('Failed to load activities (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  static Future<void> deleteActivity(int activityId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.activityDelete(activityId.toString())}?user_id=1'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        throw Exception('Failed to delete activity (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }
}
