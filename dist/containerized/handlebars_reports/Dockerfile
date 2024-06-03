ARG RUST_VERSION

FROM rust:${RUST_VERSION}
ARG HBS_VERSION
# Required to persist ${HBS_VERSION} at runtime
ENV HBS_ARG "/out/hbs__${HBS_VERSION}"
COPY . /handlebar
WORKDIR /handlebar

# Required for Darwin build - see: https://github.com/rust-lang/rust/issues/112501#issuecomment-1908527957
RUN apt-get update -yqq
RUN apt-get install -yqq --no-install-recommends build-essential
RUN apt-get install -yqq clang gcc g++ zlib1g-dev libmpc-dev libmpfr-dev libgmp-dev cmake libxml2-dev libssl-dev zip unzip
RUN curl -L https://github.com/roblabla/MacOSX-SDKs/releases/download/13.3/MacOSX13.3.sdk.tar.xz | tar xJ

RUN rustup target add x86_64-apple-darwin
RUN rustup target add x86_64-unknown-linux-gnu
CMD /handlebar/build.sh ${HBS_ARG}
