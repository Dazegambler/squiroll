from silkeh/clang:18 as build
workdir /src

copy . .
run ./build.sh

from debian:stable-slim
copy --from=build /src/aocf_server.run .

expose 5001/tcp
expose 5001/udp
cmd ["./aocf_server.run", "5001"]

