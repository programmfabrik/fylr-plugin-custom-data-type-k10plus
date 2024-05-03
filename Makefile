ZIP_NAME ?= "customDataTypek10plus.zip"
PLUGIN_NAME = "custom-data-type-gvk"

# coffescript-files to compile
COFFEE_FILES = commons.coffee \
	CustomDataTypek10plus.coffee \
	CustomDataTypek10plusFacet.coffee \
	k10plusUtilities.coffee

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build ## build all

build: clean ## clean, compile, copy files to build folder

				npm install --save node-fetch # install needed node-module

				mkdir -p build
				mkdir -p build/$(PLUGIN_NAME)
				mkdir -p build/$(PLUGIN_NAME)/webfrontend
				mkdir -p build/$(PLUGIN_NAME)/updater
				mkdir -p build/$(PLUGIN_NAME)/l10n

				mkdir -p src/tmp # build code from coffee
				cp easydb-library/src/commons.coffee src/tmp
				cp src/webfrontend/*.coffee src/tmp
				cd src/tmp && coffee -b --compile ${COFFEE_FILES} # bare-parameter is obligatory!

				# first: commons! Important
				cat src/tmp/commons.js > build/$(PLUGIN_NAME)/webfrontend/customDataTypek10plus.js

				cat src/tmp/CustomDataTypek10plus.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypek10plus.js
				cat src/tmp/CustomDataTypek10plusFacet.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypek10plus.js
				cat src/tmp/k10plusUtilities.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypek10plus.js

				cp src/updater/k10plusUpdater.js build/$(PLUGIN_NAME)/updater/k10plusUpdater.js # build updater
				cat src/tmp/k10plusUtilities.js >> build/$(PLUGIN_NAME)/updater/k10plusUpdater.js
				cp package.json build/$(PLUGIN_NAME)/package.json
				cp -r node_modules build/$(PLUGIN_NAME)/
				rm -rf src/tmp # clean tmp

				cp l10n/customDataTypek10plus.csv build/$(PLUGIN_NAME)/l10n/customDataTypek10plus.csv # copy l10n

				cp src/webfrontend/css/main.css build/$(PLUGIN_NAME)/webfrontend/customDataTypek10plus.css # copy css
				cp manifest.master.yml build/$(PLUGIN_NAME)/manifest.yml # copy manifest

clean: ## clean
				rm -rf build

zip: build ## build zip file
			cd build && zip ${ZIP_NAME} -r $(PLUGIN_NAME)/
