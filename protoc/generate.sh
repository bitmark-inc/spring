#!/bin/sh

GOLANG_PROTO_PATH=../fbm-api/protomodel

for protofile in ./*.proto; do
    # generate for golang
    protoc -I=. -I=$GOPATH/src -I=$GOPATH/src/github.com/gogo/protobuf/protobuf --gofast_out=import_path=protomodel:$GOLANG_PROTO_PATH $protofile || continue
    echo "Generated file" $GOLANG_PROTO_PATH $protofile
done