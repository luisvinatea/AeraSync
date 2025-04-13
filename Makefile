# Declare targets that are not files, so 'make' always runs the commands
# Added clean, deploy, all to the phony list
.PHONY: run-flutter build-web gen-l10n test clean deploy all

# Default target: Generate localization and run tests
all: gen-l10n test

# Target to run the Flutter app on Chrome for development
run-flutter:
	flutter run -d chrome

# Target to build the release version of the web application
build-web:
	flutter build web --release

# Target to generate Dart localization files from .arb files
gen-l10n:
	flutter gen-l10n

# Target to run all tests in the 'test' directory
# Added gen-l10n dependency to ensure localizations are up-to-date before testing
test: gen-l10n
	flutter test

# Target to clean Flutter build artifacts
clean:
	flutter clean

# Target to build and then deploy using the deploy.sh script
# Assumes deploy.sh is executable and in the project root
deploy: build-web
	./deploy.sh

