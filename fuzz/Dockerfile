# Build Stage
FROM --platform=linux/amd64 rustlang/rust:nightly as builder

ENV DEBIAN_FRONTEND=noninteractive
## Install build dependencies.
RUN apt-get update 
RUN apt-get install -y cmake clang
RUN cargo install cargo-fuzz

## Add source code to the build stage.
ADD . /fastcrypto/

WORKDIR /fastcrypto/fuzz/

RUN cargo +nightly fuzz build

FROM --platform=linux/amd64 rustlang/rust:nightly

## TODO: Change <Path in Builder Stage>

COPY --from=builder /fastcrypto/fuzz/target/x86_64-unknown-linux-gnu/release/sha256 /

COPY --from=builder /fastcrypto/fuzz/target/x86_64-unknown-linux-gnu/release/blake /

COPY --from=builder /fastcrypto/fuzz/target/x86_64-unknown-linux-gnu/release/blake3 /

COPY --from=builder /fastcrypto/fuzz/target/x86_64-unknown-linux-gnu/release/keccak /

COPY --from=builder /fastcrypto/fuzz/target/x86_64-unknown-linux-gnu/release/sha3_256 /

COPY --from=builder /fastcrypto/fuzz/target/x86_64-unknown-linux-gnu/release/sha512 /