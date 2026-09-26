# Makefile for Kubo North (Elderly Mobile App)
# Supports development, testing (iOS/Android), analysis, and builds.

FLUTTER ?= $(shell which flutter 2>/dev/null || echo "/Users/zlgonzalez/Documents/app/flutter/bin/flutter")
DART ?= $(shell which dart 2>/dev/null || dirname $(FLUTTER)/dart)

API_URL ?= http://localhost:8080/api/v1
USE_MOCK ?= true
ENV ?= dev

.PHONY: all help run run-prod test test-unit test-ios test-android analyze format clean get build-apk build-ios

all: help

help:
	@echo "Kubo North Mobile App Development Commands"
	@echo "------------------------------------------"
	@echo "make run            - Run app in debug mode with mock data providers (default)"
	@echo "make run-prod       - Run app connected to microservices (USE_MOCK=false API_URL=...)"
	@echo "make test           - Run all unit and widget tests"
	@echo "make test-ios       - Run iOS-specific widget tests and Cupertino checks"
	@echo "make test-android   - Run Android-specific widget tests and Material checks"
	@echo "make analyze        - Run dart analyze and lint rules"
	@echo "make format         - Format all Dart source files"
	@echo "make clean          - Clean build cache and transient files"
	@echo "make get            - Fetch pub dependencies"
	@echo "make build-apk      - Build Android release APK"
	@echo "make build-ios      - Build iOS release bundle (requires macOS & Xcode)"

get:
	$(FLUTTER) pub get

run:
	$(FLUTTER) run \
		--dart-define=USE_MOCK_DATA=true \
		--dart-define=API_BASE_URL=$(API_URL) \
		--dart-define=ENVIRONMENT=$(ENV)

run-prod:
	$(FLUTTER) run \
		--dart-define=USE_MOCK_DATA=false \
		--dart-define=API_BASE_URL=$(API_URL) \
		--dart-define=ENVIRONMENT=prod

test:
	$(FLUTTER) test

test-unit:
	$(FLUTTER) test test/unit/

test-ios:
	$(FLUTTER) test test/platform/ios_demo_login_test.dart test/platform/ios_family_portal_test.dart test/platform/ios_story_modal_test.dart test/widget/

test-android:
	$(FLUTTER) test test/platform/android_demo_login_test.dart test/platform/android_family_portal_test.dart test/widget/

analyze:
	$(FLUTTER) analyze

format:
	$(DART) format lib test

clean:
	$(FLUTTER) clean
	rm -rf .dart_tool build

build-apk:
	$(FLUTTER) build apk \
		--dart-define=USE_MOCK_DATA=$(USE_MOCK) \
		--dart-define=API_BASE_URL=$(API_URL)

build-ios:
	$(FLUTTER) build ios --no-codesign \
		--dart-define=USE_MOCK_DATA=$(USE_MOCK) \
		--dart-define=API_BASE_URL=$(API_URL)
