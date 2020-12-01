#!/usr/bin/env bash

pub run test --coverage ./coverage test/dart_remarkable_api_test.dart
format_coverage --packages .packages -i coverage/test/dart_remarkable_api_test.dart.vm.json -o coverage/test/test.lcov -l
genhtml -o coverage/html/ coverage/test/test.lcov -q
echo file://$(pwd)/coverage/html/index.html
