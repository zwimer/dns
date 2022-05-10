FROM golang:1.15

# Source
RUN go get github.com/miekg/dns
RUN go build github.com/miekg/dns

# Libfuzzer
RUN apt-get update \
 && apt-get install -y clang \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build deps
WORKDIR src/github.com/miekg/dns/
RUN make -f Makefile.fuzz get

# Build (Fuzz or FuzzNewRR)
ARG TARGET=FuzzNewRR
RUN go-fuzz-build -x -libfuzzer \
	-func "${TARGET}" \
	-tags fuzz \
	-o build.a \
	github.com/miekg/dns

# Make libfuzzer target
RUN clang -fsanitize=fuzzer build.a -o build

# Run
RUN ln ./build /fuzzme
CMD /fuzzme
