import 'package:flutter/material.dart';

class ActivityModel {
  final int? id;
  final String action;
  final String entityType;
  final String? entityId;
  final String title;
  final String? description;
  final DateTime createdAt;

  // UI-only fields (computed from backend data)
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const ActivityModel({
    this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.title,
    this.description,
    required this.createdAt,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    try {
      final action = json['action'] as String? ?? '';
      final entityType = json['entityType'] as String? ?? json['entity_type'] as String? ?? '';
      final title = json['title'] as String? ?? '';
      final description = json['description'] as String? ?? '';
      final createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now());

      // Compute UI fields
      final subtitle = description.isNotEmpty ? description : '$action $entityType';
      final time = _formatTime(createdAt);
      final icon = _getIconForEntityType(entityType, action);
      final color = _getColorForAction(action);

      return ActivityModel(
        id: json['id'] as int?,
        action: action,
        entityType: entityType,
        entityId: json['entityId'] as String? ?? json['entity_id'] as String?,
        title: title,
        description: description,
        createdAt: createdAt,
        subtitle: subtitle,
        time: time,
        icon: icon,
        color: color,
      );
    } catch (e) {
      print('Error parsing ActivityModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static IconData _getIconForEntityType(String entityType, String action) {
    final type = entityType.toLowerCase();
    final act = action.toLowerCase();

    if (type.contains('invoice')) {
      if (act.contains('generated') || act.contains('sent')) {
        return Icons.send_rounded;
      } else if (act.contains('payment') || act.contains('paid')) {
        return Icons.check_circle_rounded;
      }
      return Icons.description_rounded;
    } else if (type.contains('customer') || type.contains('client')) {
      return Icons.person_rounded;
    } else if (type.contains('vendor')) {
      return Icons.business_rounded;
    } else if (type.contains('quotation')) {
      return Icons.request_quote_rounded;
    } else if (type.contains('purchase')) {
      return Icons.shopping_bag_rounded;
    } else if (type.contains('lead')) {
      return Icons.people_outline_rounded;
    } else if (type.contains('item') || type.contains('product')) {
      return Icons.inventory_2_rounded;
    } else if (act.contains('deleted')) {
      return Icons.delete_rounded;
    } else if (act.contains('updated')) {
      return Icons.edit_rounded;
    } else if (act.contains('created')) {
      return Icons.add_circle_rounded;
    }

    return Icons.info_rounded;
  }

  static Color _getColorForAction(String action) {
    final act = action.toLowerCase();

    if (act.contains('created') || act.contains('added')) {
      return const Color(0xFF10B981); // success green
    } else if (act.contains('deleted') || act.contains('overdue') || act.contains('cancelled')) {
      return const Color(0xFFEF4444); // error red
    } else if (act.contains('updated') || act.contains('modified')) {
      return const Color(0xFFF59E0B); // warning orange
    } else if (act.contains('payment') || act.contains('paid') || act.contains('received')) {
      return const Color(0xFF10B981); // success green
    } else if (act.contains('generated') || act.contains('sent')) {
      return const Color(0xFF7C3AED); // primary purple
    }

    return const Color(0xFF06B6D4); // info cyan
  }
}
