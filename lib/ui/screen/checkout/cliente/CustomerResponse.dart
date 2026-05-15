import 'package:dashboard/modelli/customer.dart';

class CustomerResponse {
  final List<CustomerModel> items;
  final int total;

  CustomerResponse({
    required this.items,
    required this.total,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    final data = json["data"] ?? {};

    final List list = data["records"] ?? [];

    return CustomerResponse(
      items: list.map((e) => CustomerModel.fromJson(e)).toList(),
      total: data["numberOfAllRecords"] ?? 0,
    );
  }
}
