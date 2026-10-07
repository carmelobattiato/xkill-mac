APP_NAME = xkill-mac
APP_BUNDLE = $(APP_NAME).app
BINARY    = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
VERSION   = $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")

.PHONY: all build app icon install dmg clean

all: app

build:
	swift build -c release

app: build icon
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp .build/release/$(APP_NAME)       $(BINARY)
	@cp Sources/$(APP_NAME)/Info.plist   $(APP_BUNDLE)/Contents/Info.plist
	@cp AppIcon.icns                     $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@cp Assets/skull_normal.png          $(APP_BUNDLE)/Contents/Resources/skull_normal.png
	@cp Assets/skull_active.png          $(APP_BUNDLE)/Contents/Resources/skull_active.png
	@codesign --sign - --force --deep    $(APP_BUNDLE)
	@echo "✅ Built and signed $(APP_BUNDLE)"

icon:
	@if [ ! -f AppIcon.icns ]; then swift create_icon.swift; fi

install: app
	@rm -rf /Applications/$(APP_BUNDLE)
	@cp -r $(APP_BUNDLE) /Applications/
	@echo "✅ Installed to /Applications/$(APP_BUNDLE)"

dmg: app
	@rm -rf _dmg_tmp $(APP_NAME).dmg
	@mkdir _dmg_tmp
	@cp -r $(APP_BUNDLE) _dmg_tmp/
	@ln -s /Applications _dmg_tmp/Applications
	@hdiutil create \
		-volname "$(APP_NAME) $(VERSION)" \
		-srcfolder _dmg_tmp \
		-ov -format UDZO \
		$(APP_NAME).dmg
	@rm -rf _dmg_tmp
	@echo "✅ Created $(APP_NAME).dmg"

clean:
	swift package clean
	@rm -rf $(APP_BUNDLE) _dmg_tmp $(APP_NAME).dmg
