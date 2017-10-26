### --------------------------------------------------------------------------------------------------------------------
### Variables
### (https://www.gnu.org/software/make/manual/html_node/Using-Variables.html#Using-Variables)
### --------------------------------------------------------------------------------------------------------------------

BUILD_DIR ?= build/

NAME=housekeeper
REPO=github.com/gregbiv/${NAME}

# Custom local environment file
ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

SRC_DIRS=cmd

BINARY=housekeeper
BINARY_SRC=$(REPO)/cmd/${NAME}

GO_LINKER_FLAGS=-ldflags="-s -w"

# Other config
NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m

# Space separated patterns of packages to skip in list, test, format.
IGNORED_PACKAGES := /vendor/

### --------------------------------------------------------------------------------------------------------------------
### RULES
### (https://www.gnu.org/software/make/manual/html_node/Rule-Introduction.html#Rule-Introduction)
### --------------------------------------------------------------------------------------------------------------------
.PHONY: all clean deps build install

all: clean deps build install

# Installs our project: copies binaries
#-----------------------------------------------------------------------------------------------------------------------
install: install-bin

install-bin:
	@printf "$(OK_COLOR)==> Installing project$(NO_COLOR)\n"
	go install -v $(BINARY_SRC)

# Building
#-----------------------------------------------------------------------------------------------------------------------
build: build-bin

build-bin:
	@printf "$(OK_COLOR)==> Building$(NO_COLOR)\n"
	@go build -o ${BUILD_DIR}/${BINARY} ${GO_LINKER_FLAGS} ${BINARY_SRC}

# Dependencies
#-----------------------------------------------------------------------------------------------------------------------
deps:
	@echo "$(OK_COLOR)==> Installing glide dependencies$(NO_COLOR)"
	@glide install

deps-dev:
	@printf "$(OK_COLOR)==> Installing Linters$(NO_COLOR)\n"
	@go get -u golang.org/x/tools/cmd/goimports
	@go get -u github.com/golang/lint/golint

# Lint
#-----------------------------------------------------------------------------------------------------------------------
lint:
	@echo "$(OK_COLOR)==> Linting... $(NO_COLOR)"
	@golint $(SRC_DIRS)
	@goimports -l -w $(SRC_DIRS)

# House keeping
#-----------------------------------------------------------------------------------------------------------------------
clean:
	@printf "$(OK_COLOR)==> Cleaning project$(NO_COLOR)\n"
	if [ -d ${BUILD_DIR} ] ; then rm -rf ${BUILD_DIR} ; fi
