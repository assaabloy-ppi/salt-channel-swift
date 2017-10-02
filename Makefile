VERSION = $(shell grep s.version SaltChannel.podspec | cut -f2 -d= | cut -f1 -d{)

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
