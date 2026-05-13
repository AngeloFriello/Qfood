class FiscalHelper {

  static FiscalHelper? _instance;
  static FiscalHelper instance () => _instance ??= FiscalHelper();

  /// Ottieni timestamp stile MySQL
  String getCurrentTimestamp(){
    DateTime time = DateTime.now();
    return "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  /// Ottieni data da timestamp
  String getDateFromTimestamp(){
    return getCurrentTimestamp().split(" ")[0];
  }

  /// Formatta timestamp per nome file
  String getTimestampFileName(){
    return getCurrentTimestamp().replaceAll("-", "_").replaceAll(" ", "").replaceAll(":", "_");
  }

}