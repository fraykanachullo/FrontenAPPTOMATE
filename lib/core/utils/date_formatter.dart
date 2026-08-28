import 'package:intl/intl.dart';

class DateFormatter {
  static String toDDMMYYYY(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
  static String toDDMMYYYYHHMM(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);
  static String toIsoUtc(DateTime dt) => dt.toUtc().toIso8601String();
  static DateTime? fromIso(String? s) => s == null ? null : DateTime.tryParse(s);
}
