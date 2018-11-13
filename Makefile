PROJECT       = SaltChannel
VERSION       = $(shell grep s.version $(PROJECT).podspec | cut -f2 -d= | cut -f1 -d{)

SWIFT         = swift
SWIFT_FLAGS   = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
SYMROOT				= ./build

IOS_FLAGS     = -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6S'
OSX_FLAGS     = -sdk macosx

XCODE         = xcodebuild
XCODE_PROJECT = $(PROJECT).xcodeproj
XCODE_WORKSPACE = $(PROJECT).xcworkspace
XCODE_SCHEME  = $(PROJECT)-Tests
XCODE_FLAGS   =
XCODE_CMD     = $(XCODE) -workspace $(XCODE_WORKSPACE) $(XCODE_FLAGS)

SYMROOT="./build"

all: pod-install lint xcodebuild-ios

test: build
	$(SWIFT) test $(SWIFT_FLAGS)

build:
	$(SWIFT) build $(SWIFT_FLAGS)

lint:
	swiftlint

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
	git tag -a $(VERSION) -m "New $(PROJECT) release: $(VERSION)"

pushtag:
	git push --follow-tags

verify:
	pod spec lint $(PROJECT).podspec

list:
	xcodebuild -project $(PROJECT).xcodeproj  -list
	xcodebuild -workspace $(PROJECT).xcworkspace  -list

xcodebuild-ios:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(IOS_FLAGS) | xcpretty && exit $(PIPESTATUS[0])

xcodebuild-osx:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) | xcpretty && exit $(PIPESTATUS[0])

dependencies:
	$(SWIFT_CMD) package show-dependencies

describe: list dependencies
	$(SWIFT_CMD) package describe

coverage:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) -configuration Debug -enableCodeCoverage YES test
	slather coverage --scheme $(XCODE_SCHEME) --show $(XCODE_PROJECT)
