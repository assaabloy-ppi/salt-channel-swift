VERSION = $(shell grep s.version SaltChannel.podspec | cut -f2 -d= | cut -f1 -d{)
FLAGS = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

all: pod-install lint build test

test: build
	swift test ${FLAGS}

build:
	swift build ${FLAGS}

lint:
	swiftlint

pod-install:
	pod install

pod-update:
	pod update

clean:
	rm -rf .build *~ .*~ *.log

cleaner: clean
	rm -rf Pods

version:
	@echo ${VERSION}

tag:
	git tag ${VERSION}

pushtag: tag
	git push origin --tags

verify:
	pod spec lint SaltChannel.podspec

format:
	swiftformat --hexliteralcase lowercase --hexgrouping none --ranges nospace --wrapelements beforefirst --self remove Package.swift

list:
	xcodebuild -project SaltChannel.xcodeproj  -list
	xcodebuild -workspace SaltChannel.xcworkspace  -list
