dart pub global activate coverage
dart test --coverage="coverage"
format_coverage --lcov --in=coverage --out=coverage.lcov --packages=.packages --report-on=lib
genhtml coverage.lcov -o coverage
open coverage/index.html