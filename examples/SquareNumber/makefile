# Example settings
LAMBDA_NAME=SquareNumber
EXECUTABLE=$(LAMBDA_NAME)
LAMBDA_ZIP=lambda.zip

SWIFT_VERSION=5.1.4
SWIFT_DOCKER_IMAGE=fabianfett/amazonlinux-swift:${SWIFT_VERSION}-amazonlinux2-dev

clean_lambda:
	rm bootstrap || true
	rm lambda.zip || true

build_lambda:
	docker run \
			--rm \
			--volume "$(shell pwd)/../..:/src" \
			--workdir "/src/examples/$(LAMBDA_NAME)/" \
			$(SWIFT_DOCKER_IMAGE) \
			swift build -c release

package_lambda: build_lambda
	cp .build/release/$(EXECUTABLE) ./bootstrap
	zip -r -j $(LAMBDA_ZIP) ./bootstrap

download_layer:
	curl -o swift-${SWIFT_VERSION}-RELEASE.zip https://amazonlinux-swift.s3.eu-central-1.amazonaws.com/layers/swift-${SWIFT_VERSION}-RELEASE.zip
	unzip swift-${SWIFT_VERSION}-RELEASE.zip -d swift-lambda-layer
	rm swift-${SWIFT_VERSION}-RELEASE.zip
