
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

String newUuidV4(){
  return _uuid.v4();
}

