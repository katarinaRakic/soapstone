FROM golang:1.26
WORKDIR /src
COPY . .
RUN go build -o /soapstone ./cmd/soapstone
EXPOSE 8080
ENTRYPOINT ["/soapstone"]
CMD ["serve"]

