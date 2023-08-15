FROM --platform=$TARGETPLATFORM golang:1.20-alpine as builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG SEGMENT_WRITE_KEY
ARG VERSION
LABEL MAINTAINER="mlabouardy <mohamed@tailwarden.com>"

# BUILDPLATFORM macOS M1 : arm64 / TARGETPLATFORM Linux amd64
RUN echo "Running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log

ENV SEGMENT_WRITE_KEY $SEGMENT_WRITE_KEY
ENV VERSION $VERSION

# COPY bin/komiser /usr/bin/komiser
WORKDIR /app
COPY . /app

ARG EXECUTABLE=komiser

ARG GO_FLAGS="-ldflags"

RUN go mod tidy
RUN go build -o bin/${EXECUTABLE} .

# Use a minimal Alpine image as the base for the final image
FROM  --platform=$TARGETPLATFORM  alpine:3.16

# Set the working directory inside the container
WORKDIR /app

# Copy the built executable from the build container
COPY --from=builder /app/bin/${EXECUTABLE} /usr/bin/${EXECUTABLE}
RUN chmod +x  /usr/bin/${EXECUTABLE}
EXPOSE $PORT
ENTRYPOINT ["komiser", "start"]
