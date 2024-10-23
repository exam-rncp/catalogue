FROM golang:1.7

COPY . /go/src/github.com/exam-rncp/catalogue
WORKDIR /go/src/github.com/exam-rncp/catalogue

RUN go get -u github.com/FiloSottile/gvt
RUN gvt restore
