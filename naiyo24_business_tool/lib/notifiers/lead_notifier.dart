import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/lead_services.dart';
import 'package:naiyo24_business_tool/models/lead_model.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';

class LeadNotifier extends StateNotifier<List<LeadModel>> {
  LeadNotifier() : super([]);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadLeads({String? status}) async {
    _isLoading = true;
    try {
      final leads = await LeadService.getLeads(status: status);
      state = leads;
    } catch (e) {
      // Keep existing state on error
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<LeadModel> createLead({
    required String name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? source,
  }) async {
    final lead = await LeadService.createLead(
      name: name,
      email: email,
      phone: phone,
      company: company,
      notes: notes,
      source: source,
    );
    state = [lead, ...state];
    return lead;
  }

  Future<LeadModel> updateLead(int id, Map<String, dynamic> updates) async {
    final updatedLead = await LeadService.updateLead(id, updates);
    state = [
      for (final lead in state)
        if (lead.id == id) updatedLead else lead,
    ];
    return updatedLead;
  }

  Future<void> updateLeadStatus(int id, LeadStatus newStatus) async {
    await updateLead(id, {'status': newStatus.value});
  }

  Future<void> deleteLead(int id) async {
    await LeadService.deleteLead(id);
    state = state.where((lead) => lead.id != id).toList();
  }

  Future<CustomerModel> convertToCustomer(int id) async {
    final customer = await LeadService.convertToCustomer(id);
    // Update lead status to converted
    state = [
      for (final lead in state)
        if (lead.id == id)
          lead.copyWith(status: LeadStatus.converted)
        else
          lead,
    ];
    return customer;
  }

  List<LeadModel> getLeadsByStatus(LeadStatus status) {
    return state.where((lead) => lead.status == status).toList();
  }

  int getCountByStatus(LeadStatus status) {
    return state.where((lead) => lead.status == status).length;
  }
}

final leadNotifierProvider =
    StateNotifierProvider<LeadNotifier, List<LeadModel>>((ref) {
  final notifier = LeadNotifier();
  notifier.loadLeads(); // Auto-load on init
  return notifier;
});
