FROM golang:alpine as builder

RUN apk add git

WORKDIR /root
COPY . /root
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# TODO change to distroless
FROM ubuntu:latest as prod
WORKDIR /root/
COPY --from=builder /root/app .
COPY --from=builder /root/conf /root/conf
RUN apt-get update && apt-get install -y --no-install-recommends stress-ng \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80
ENTRYPOINT ["/root/app"]
