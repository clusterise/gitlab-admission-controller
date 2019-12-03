IMAGE = gitlab-admission-controller
VERSION = 1.0.0

.PHONY: _
_: preflight build publish

.PHONY: preflight
preflight:
	go mod tidy
	go mod vendor
	go fmt gitlabrunneradmission/cmd

.PHONY: build
build:
	docker build -t $(IMAGE):$(VERSION) .

.PHONY: publish
publish:
	docker push $(IMAGE):$(VERSION)

.PHONY: certs
certs:
	[[ ! -d certs/output ]]
	mkdir certs/output
	cfssl gencert -initca certs/ca-csr.json | cfssljson -bare certs/output/ca -
	cfssl gencert -ca=certs/output/ca.pem -ca-key=certs/output/ca-key.pem -config=certs/ca-config.json -profile=server certs/csr.json | cfssljson -bare certs/output/server
