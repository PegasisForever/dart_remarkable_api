// @dart=2.9
import 'package:test/test.dart';

import 'dart_remarkable_api_test.dart' as dart_remarkable_api_test;
import 'remarkable_http_client_test.dart' as remarkable_http_client_test;

void main(){
  group("dart_remarkable_api_test", dart_remarkable_api_test.main);
  group("remarkable_http_client_test", remarkable_http_client_test.main);
}
