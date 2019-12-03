FROM golang:1.13.5-alpine3.11 as builder
ARG GITLAB_TOKEN

WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -mod vendor -o gitlab-runner-admission gitlabrunneradmission/cmd

FROM alpine:3.11
COPY --from=builder /src/gitlab-runner-admission /opt/gitlab-runner-admission
ENTRYPOINT ["/opt/gitlab-runner-admission"]
