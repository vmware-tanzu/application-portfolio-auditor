This file contains a few snippets to test and validate the creation of the CSA-Bagger container image.

* Snippet to unzip the content of the generated container image 

```sh
docker buildx build --platform "linux/amd64" -f "Dockerfile" -t bagger:1.0.1 .
rm -Rf /tmp/image.tar /tmp/image
mkdir -p /tmp/image
docker export "$(docker create bagger:1.0.1)" > /tmp/image.tar
tar -x -f /tmp/image.tar -C /tmp/image
unzip /tmp/image/app/bagger.jar -d /tmp/image/app
cat /tmp/image/app/META-INF/MANIFEST.MF
```

* Snippet to build the CSA bagger container image

```
ARCH="$(uname -m)"
export DOCKER_ARCH="$([[ "${ARCH}" == "arm64" ]] && echo "arm64" || echo "amd64")"
export DOCKER_PLATFORM="linux/${DOCKER_ARCH}"
docker buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t csa-bagger:1.0.1 .
```

* Snippet to execute the built container image

```
docker run --rm -v "${APP_DIR_OUT}:/output" bagger:1.0.1 "/output/csa.db" "/output/results_extracted_bagger__.csv" "${SEPARATOR}"
```
