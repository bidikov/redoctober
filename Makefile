NAME      := redoctober
VERSION   := 0.1
ITERATION := $(shell date +%s)
REVISION  := $(shell git log -n1 --pretty=format:%h)

export GOPATH := $(PWD)

BUILD_DEPS := go mercurial

.PHONY: external
external:
	@go get code.google.com/p/go.crypto/scrypt

.PHONY: all
all: external $(NAME)

.PHONY: test
test:
	@go test $(NAME)/...

.PHONY: print-builddeps
print-builddeps:
	@echo $(BUILD_DEPS)

.PHONY: $(NAME)
$(NAME): bin/$(NAME)

SRC := $(shell find src/$(NAME) -type f)
bin/$(NAME): $(SRC)
	@go fmt $(NAME)
	@go install -tags "$(TAGS)" -ldflags "$(LDFLAGS)" $(NAME)

BUILD_PATH               := build
INSTALL_PREFIX           := usr/local
REDOCTOBER_BUILD_PATH    := $(BUILD_PATH)/$(INSTALL_PREFIX)/$(NAME)

FPM := fakeroot fpm -C $(BUILD_PATH) \
	-s dir \
	-t deb \
	--deb-compression bzip2 \
	-v $(VERSION) \
	--iteration $(ITERATION)

DEB_PACKAGE := $(NAME)_$(VERSION)-$(ITERATION)_amd64.deb
$(DEB_PACKAGE): TAGS := release
$(DEB_PACKAGE): LDFLAGS := -X main.version $(VERSION) -X main.revision $(REVISION)
$(DEB_PACKAGE): clean all
	mkdir -p $(REDOCTOBER_BUILD_PATH)
	cp bin/$(NAME) $(REDOCTOBER_BUILD_PATH)
	$(FPM) -n $(NAME) .

register-%.deb: ; $(PACKAGE_REGISTER_BIN) $*.deb

.PHONY: cf-package
cf-package: $(DEB_PACKAGE)

.PHONY: clean-package
clean-package:
	$(RM) -r $(BUILD_PATH)
	$(RM) $(DEB_PACKAGE)

.PHONY: clean
clean: clean-package
	@go clean -i $(NAME)/...
	@$(RM) -r pkg

print-%: ; @echo $*=$($*)
