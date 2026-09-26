FROM --platform=$TARGETPLATFORM golang:1.26-alpine
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY main.go .
RUN echo "Building iot-sample for ${TARGETPLATFORM}"
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o server main.go

FROM alpine:latest
RUN adduser -D runner
USER runner
COPY --from=0 /app/server .
ENV PORT 8080
CMD ["./server"]