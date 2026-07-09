class DashboardStatsModel {
  const DashboardStatsModel({
    required this.totalInvoices,
    required this.invoiceAmount,
    required this.pendingInvoices,
    required this.overdueAmount,
    required this.overdueCount,
    required this.totalExpenses,
    required this.expenseAmount,
    required this.totalQuotations,
    required this.quotationAmount,
    required this.totalSalaries,
    required this.salaryAmount,
    required this.activeCustomers,
    required this.totalLeads,
    required this.newLeads,
  });

  final int totalInvoices;
  final double invoiceAmount;
  final int pendingInvoices;
  final double overdueAmount;
  final int overdueCount;
  final int totalExpenses;
  final double expenseAmount;
  final int totalQuotations;
  final double quotationAmount;
  final int totalSalaries;
  final double salaryAmount;
  final int activeCustomers;
  final int totalLeads;
  final int newLeads;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalInvoices: json['total_invoices'] as int? ?? 0,
      invoiceAmount: (json['invoice_amount'] as num?)?.toDouble() ?? 0.0,
      pendingInvoices: json['pending_invoices'] as int? ?? 0,
      overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0.0,
      overdueCount: json['overdue_count'] as int? ?? 0,
      totalExpenses: json['total_expenses'] as int? ?? 0,
      expenseAmount: (json['expense_amount'] as num?)?.toDouble() ?? 0.0,
      totalQuotations: json['total_quotations'] as int? ?? 0,
      quotationAmount: (json['quotation_amount'] as num?)?.toDouble() ?? 0.0,
      totalSalaries: json['total_salaries'] as int? ?? 0,
      salaryAmount: (json['salary_amount'] as num?)?.toDouble() ?? 0.0,
      activeCustomers: json['active_customers'] as int? ?? 0,
      totalLeads: json['total_leads'] as int? ?? 0,
      newLeads: json['new_leads'] as int? ?? 0,
    );
  }

  factory DashboardStatsModel.empty() {
    return const DashboardStatsModel(
      totalInvoices: 0,
      invoiceAmount: 0.0,
      pendingInvoices: 0,
      overdueAmount: 0.0,
      overdueCount: 0,
      totalExpenses: 0,
      expenseAmount: 0.0,
      totalQuotations: 0,
      quotationAmount: 0.0,
      totalSalaries: 0,
      salaryAmount: 0.0,
      activeCustomers: 0,
      totalLeads: 0,
      newLeads: 0,
    );
  }
}
