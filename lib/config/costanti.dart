//Configurazione base
String defaultInstance = "";
const String apiBaseUrl = "https://instance1-api.qfood.it/api/v1/pos";

const String posApiKey =
    "BM97GCOPKANicNAxisEhvgZKxYcrzAcuAkep9wD5I6d5wOUiGEoVd92DpSuQGLLGR0KgofzNdgMYuMWg5k9N1Ljm8CldT8AGkhwexBykEc4ELfOTcQjSyMhbemIgSkxx";

//Chiavi API per istanze QFood
const Map<String, String> apiKeysByInstance = {
  "instance1":
      "hQvNLLQUV6ljx1JF0CgTKWjT5c6Qsp6lnzxdkTykG7b2Dtw1120TLPZpMRccgMS1pAhblDBQKF1l4n25DUeqvwPyKb9JAnLIM65BqiOKVFgVCdZdy9gdLj8yT48SQRZp",
  "instance2":
      "hQvNLLQUV6ljx1JF0CgTKWjT5c6Qsp6lnzxdkTykG7b2Dtw1120TLPZpMRccgMS1pAhblDBQKF1l4n25DUeqvwPyKb9JAnLIM65BqiOKVFgVCdZdy9gdLj8yT48SQRZp",
  "instance3":
      "hQvNLLQUV6ljx1JF0CgTKWjT5c6Qsp6lnzxdkTykG7b2Dtw1120TLPZpMRccgMS1pAhblDBQKF1l4n25DUeqvwPyKb9JAnLIM65BqiOKVFgVCdZdy9gdLj8yT48SQRZp",
};

//Default fallback (se istanza non trovata)
const String defaultApiKey =
    "hQvNLLQUV6ljx1JF0CgTKWjT5c6Qsp6lnzxdkTykG7b2Dtw1120TLPZpMRccgMS1pAhblDBQKF1l4n25DUeqvwPyKb9JAnLIM65BqiOKVFgVCdZdy9gdLj8yT48SQRZp";

const String APIKEYRESELLER =
    "So374ZU28fVWNQDFCfT4hklLViHJuKdcPn4P1XsjKXXyWD3Um1ycn9JnxduklDruQBlPkaB5PkZMAdNGgE14Olvd4f4YSL3MCocGthbohBk7FrbgJJsAoFCXeK3xm8WX";
// ritorna la chiave corretta
String apiKeyForInstance(String? istanza) {
  return apiKeysByInstance[istanza] ?? defaultApiKey;
}

const String customerGuidCreate = "a4444a9b4af2";
const String customerGuidDetail = "22d781273a4b";

const String backofficeKey =
    "hQvNLLQUV6ljx1JF0CgTKWjT5c6Qsp6lnzxdkTykG7b2Dtw1120TLPZpMRccgMS1pAhblDBQKF1l4n25DUeqvwPyKb9JAnLIM65BqiOKVFgVCdZdy9gdLj8yT48SQRZp";

const String customerBaseUrl = "https://instance1-api.qfood.it/api/v1/customer";

String apiKeyForUrl(String url, String? istanza) {
  // Tutto ciò che è POS usa la POS API KEY
  if (url.contains("/pos/")) {
    return posApiKey;
  }

  // Tutto il resto usa la chiave per istanza
  return apiKeysByInstance[istanza] ?? defaultApiKey;
}

/// GUID UNICA E CORRETTA PER:
/// GET /customer/getCustomerById
const String customerGuidGet = "9fec663e8ba0";

const String helperBaseUrl = "https://instance1-api.qfood.it/api/v1/helper";
