# Copyright (c) 2024 Larry Aasen. All rights reserved.

# Run all widget tests and update the golden images
test_update_goldens:
	flutter test --update-goldens test/dive_ui_test.dart

test_widgets:
	flutter test test/dive_ui_test.dart

upload_coverage:
	bash <(curl -s https://codecov.io/bash) -t <token>

test:
	flutter test --coverage --coverage-path=lcov.info
