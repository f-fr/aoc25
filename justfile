run:
    zig build times --release=fast -Dtarget=x86_64-linux-musl

test:
    zig build test --summary all

build:
    zig build --release=fast -Dtarget=x86_64-linux-musl
