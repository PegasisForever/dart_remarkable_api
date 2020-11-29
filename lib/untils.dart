import 'dart:async';
import 'dart:isolate';

import 'package:uuid/uuid.dart';

final _uuid = Uuid();

String newUuidV4() {
  return _uuid.v4();
}

typedef ComputeCallback<Q, R> = R Function(Q message);

class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
      this.callback,
      this.message,
      this.resultPort
      );
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;

  R apply() => callback(message);
}

Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, R> configuration) async {
  final R result = await configuration.apply();
  configuration.resultPort.send(result);
}


Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message) async {
  final ReceivePort resultPort = ReceivePort();
  final Isolate isolate = await Isolate.spawn<_IsolateConfiguration<Q, R>>(
    _spawn,
    _IsolateConfiguration<Q, R>(
      callback,
      message,
      resultPort.sendPort,
    ),
  );
  final Completer<R> result = Completer<R>();
  resultPort.listen((dynamic resultData) {
    assert(resultData == null || resultData is R);
    if (!result.isCompleted)
      result.complete(resultData as R);
  });
  await result.future;
  resultPort.close();
  isolate.kill();
  return result.future;
}
