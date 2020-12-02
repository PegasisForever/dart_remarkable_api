#!/usr/bin/env bash

TEST_FILE=run_all_tests.dart
pub run test --coverage ./coverage test/$TEST_FILE
format_coverage --packages .packages -i coverage/test/$TEST_FILE.vm.json -o coverage/test/test.lcov -l
genhtml -o coverage/html/ coverage/test/test.lcov -q
echo file://$(pwd)/coverage/html/index.html
