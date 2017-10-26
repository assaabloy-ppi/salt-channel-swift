VERSION = $(shell grep s.version SaltChannel.podspec | cut -f2 -d= | cut -f1 -d{)

SWIFT         = swift
SWIFT_FLAGS   = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
SYMROOT				= ./build

IOS_FLAGS     = -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6S'
OSX_FLAGS     = -sdk macosx

XCODE         = xcodebuild
XCODE_PROJECT = SaltChannel.xcodeproj
XCODE_SCHEME  = SaltChannel
XCODE_FLAGS   =
XCODE_CMD     = $(XCODE) -project $(XCODE_PROJECT) $(XCODE_FLAGS)

SYMROOT="./build"

all: lint xcodebuild-ios xcodebuild-osx

all: pod-install lint build test

test: build
	$(SWIFT) test $(SWIFT_FLAGS)

build:
	$(SWIFT) build $(SWIFT_FLAGS)

lint:
	swiftlint

docs:
	jazzy --theme fullwidth

pod-install:
	pod install

pod-update:
	pod update

clean:
	rm -rf .build *~ .*~ *.log
	rm -rf Pods Podfile.lock
	$(XCODE_CMD) -configuration Debug clean
	$(XCODE_CMD) -configuration Release clean
	$(XCODE_CMD) -configuration Test clean
	rm -rf build

version:
	@echo $(VERSION)

tag:
	git tag -a $(VERSION) -m "New SaltChannel release: $(VERSION)"

pushtag:
	git push --follow-tags

verify:
	pod spec lint SaltChannel.podspec

list:
	xcodebuild -project SaltChannel.xcodeproj  -list
	xcodebuild -workspace SaltChannel.xcworkspace  -list

xcodebuild-ios:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(IOS_FLAGS) build-for-testing test  | xcpretty && exit $(PIPESTATUS[0])

xcodebuild-osx:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) build-for-testing test | xcpretty && exit $(PIPESTATUS[0])

dependencies:
	$(SWIFT_CMD) package show-dependencies

describe: list dependencies
	$(SWIFT_CMD) package describe

coverage:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) -configuration Debug -enableCodeCoverage YES test
	slather coverage --scheme $(XCODE_SCHEME) --show $(XCODE_PROJECT)
