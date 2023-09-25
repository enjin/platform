FROM debian as sources

WORKDIR /wallet

COPY /wallet-daemon .

FROM rust:1.59.0-buster as cargo-build

ARG PROFILE=release

ENV CARGO_HOME=/wallet/.cargo

WORKDIR /wallet

COPY --from=sources '/wallet' '/wallet'

RUN cargo build --$PROFILE --package bin

# Stage: slim
FROM debian:buster-slim as slim

ARG PROFILE=release

# Reqwest needs libssl and curl is needed to install the ca-certificates.
RUN apt-get update && \
    apt-get install -y libssl-dev wait-for-it jq curl zip dos2unix

RUN rm -rf /var/lib/apt/lists/*

# Copy wallet daemon binary.
COPY --from=cargo-build /wallet/target/$PROFILE/wallet /usr/local/bin

# Stage: wallet-daemon
FROM slim as wallet-daemon

LABEL org.opencontainers.image.source=https://github.com/enjin/wallet-daemon
LABEL org.opencontainers.image.description="Platform - Efinity Wallet Daemon"
LABEL org.opencontainers.image.licenses=LGPL-3.0-only

COPY configs/daemon/config.json /opt/app/config.json
COPY configs/daemon/.env /usr/local/bin/.env
COPY configs/daemon/start.sh /usr/local/bin/start

RUN dos2unix /opt/app/config.json
RUN dos2unix /usr/local/bin/.env
RUN dos2unix /usr/local/bin/start

CMD ["/usr/local/bin/start"]
