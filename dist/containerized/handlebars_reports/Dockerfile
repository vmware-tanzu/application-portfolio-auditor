FROM rust:1.78.0
ARG HBS_VERSION
# Required to persist ${HBS_VERSION} at runtime
ENV HBS_ARG "/out/hbs__${HBS_VERSION}"
COPY . /handlebar
WORKDIR /handlebar
RUN rustup target add x86_64-apple-darwin
RUN rustup target add x86_64-unknown-linux-gnu
CMD /handlebar/build.sh ${HBS_ARG}
