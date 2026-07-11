import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/lead_services.dart';
import 'package:naiyo24_business_tool/models/lead_model.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/providers/api_providers.dart';

class LeadNotifier extends StateNotifier<List<LeadModel>> {
  LeadNotifier(this._service) : super([]);

  final LeadService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadLeads({String? status}) async {
    _isLoading = true;
    try {
      final leads = await _service.getLeads(status: status);
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
    final lead = await _service.createLead(
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
    final updatedLead = await _service.updateLead(id, updates);
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
    await _service.deleteLead(id);
    state = state.where((lead) => lead.id != id).toList();
  }

  Future<CustomerModel> convertToCustomer(int id) async {
    final customer = await _service.convertToCustomer(id);
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
  final service = ref.watch(leadApiServiceProvider);
  final notifier = LeadNotifier(service);
  notifier.loadLeads(); // Auto-load on init
  return notifier;
});
