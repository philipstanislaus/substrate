# Note: We don't use Alpine and its packaged Rust/Cargo because they're too often out of date,
# preventing them from being used to build Substrate/Polkadot.

FROM phusion/baseimage:0.10.2 as builder
LABEL description="This is the build stage for subkey. Here we create the binary."

ARG PROFILE=release
WORKDIR /substrate

COPY . /substrate

RUN apt-get update && \
	# apt-get dist-upgrade -y && \
	apt-get install -y cmake pkg-config libssl-dev git clang

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
	export PATH="$PATH:$HOME/.cargo/bin" && \
	rustup toolchain install nightly && \
	rustup target add wasm32-unknown-unknown --toolchain nightly && \
	cargo install --git https://github.com/alexcrichton/wasm-gc && \
	rustup default nightly && \
	rustup default stable && \
	cd subkey && \
	cargo build --$PROFILE

# ===== SECOND STAGE ======

FROM phusion/baseimage:0.10.2
LABEL description="This is the 2nd stage: a very small image where we copy the subkey binary."
ARG PROFILE=release

RUN mkdir -p /root/.local/share/Polkadot && \
	ln -s /root/.local/share/Polkadot /data

COPY --from=builder /substrate/target/$PROFILE/subkey /usr/local/bin

# checks
RUN ldd /usr/local/bin/subkey && \
	/usr/local/bin/subkey --version

CMD ["/usr/local/bin/subkey"]
