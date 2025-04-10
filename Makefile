.PHONY: run-flutter build-web gen-l10n test

run-flutter:
	flutter run -d chrome

build-web:
	flutter build web --release

gen-l10n:
	flutter gen-l10n

test:
	flutter test