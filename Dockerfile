# AFTER: hardened multi-stage build.

# ---- Stage 1: build ----
FROM golang:1-alpine AS build
ARG VERSION=dev
WORKDIR /src

COPY app/go.mod ./
RUN go mod download

COPY app/ ./
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/server .

# ---- Stage 2: runtime (no shell, non-root) ----
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/server /server

USER 65532:65532
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/server", "-healthcheck"]

ENTRYPOINT ["/server"]
