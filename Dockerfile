# Prvi stage, build: ovde je ceo Go, a u finalni image odavde ide samo binary.
FROM golang:1.26 AS build
WORKDIR /src
# Prvo samo spisak zavisnosti, da ovaj layer ostane u kešu dok se on ne promeni.
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Verzija i commit dolaze spolja, sa --build-arg; bez njih ostaju dev i unknown.
ARG VERSION=dev
ARG COMMIT=unknown
# Statički binary, sa verzijom i commit-om upisanim u njega.
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags="-s -w -X github.com/urosevicvuk/soapstone/internal/buildinfo.Version=${VERSION} -X github.com/urosevicvuk/soapstone/internal/buildinfo.Commit=${COMMIT}" \
    -o /out/soapstone ./cmd/soapstone

# Drugi stage, ono što se pokreće: binary, bez shell-a i bez paketa.
FROM gcr.io/distroless/static:nonroot
COPY --from=build /out/soapstone /soapstone
# Proces ne radi kao root; 65532 je korisnik nonroot iz ovog image-a.
USER 65532:65532
EXPOSE 8080
# Docker sam proverava zdravlje kontejnera; curl ovde ne postoji, pa to radi binary.
HEALTHCHECK --interval=10s CMD ["/soapstone", "healthcheck"]
ENTRYPOINT ["/soapstone"]
CMD ["serve"]
