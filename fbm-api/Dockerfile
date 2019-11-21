FROM golang:1.13-alpine as build

WORKDIR $GOPATH/github.com/bitmark-inc/fbm-apps/fbm-api

ADD go.mod .
ADD go.sum .

RUN go mod download

ADD . .

RUN go install github.com/bitmark-inc/fbm-apps/fbm-api

# ---

FROM alpine:3.10.3
ARG dist=0.0
COPY --from=build /go/bin/fbm-api /

ENV FBM_LOG_LEVEL=INFO
ENV FBM_SERVER_VERSION=$dist
ENV FBM_STRIPE_SERVICE=fbm

CMD ["/fbm-api"]