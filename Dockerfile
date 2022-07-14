FROM golang:1.18.4-alpine3.16 as builder

ARG ARTIFACTORY_CREDS

RUN go env -w GONOSUMDB="github.com/Rookout/GoSDK"
RUN go env -w GOPROXY="https://proxy.golang.org,https://${ARTIFACTORY_CREDS}@rookout.jfrog.io/artifactory/api/go/rookout-go,direct"

RUN apk add --no-cache gcc musl-dev build-base zlib-static

WORKDIR /app
ADD go.mod go.sum ./
RUN go mod download
ADD . .

# We get the full GoSDK package explicitly so it would register it in the go.sum
# We do it after getting all of the project's files so the go.mod and go.sum will not be overwritten with the stub package
RUN go get -d github.com/Rookout/GoSDK@v0.1.13

RUN go build -tags=alpine314,rookout_static -gcflags='all=-N -l' cmd/main.go

FROM alpine:3.16 as release
WORKDIR /app
COPY --from=builder /app/main ./
COPY --from=builder /app/static ./static

COPY .git /.git

CMD ["./main"]