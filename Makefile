APP_NAME = xkill-mac
APP_BUNDLE = $(APP_NAME).app
BINARY = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

.PHONY: all build app install clean

all: app

build:
	swift build -c release

app: build icon
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp .build/release/$(APP_NAME) $(BINARY)
	@cp Sources/$(APP_NAME)/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@cp Assets/skull_normal.png $(APP_BUNDLE)/Contents/Resources/skull_normal.png
	@cp Assets/skull_active.png $(APP_BUNDLE)/Contents/Resources/skull_active.png
	@codesign --sign - --force --deep $(APP_BUNDLE)
	@echo "Built and signed $(APP_BUNDLE)"

icon:
	@if [ ! -f AppIcon.icns ]; then swift create_icon.swift; fi

install: app
	@rm -rf /Applications/$(APP_BUNDLE)
	@cp -r $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_BUNDLE)"

clean:
	swift package clean
	@rm -rf $(APP_BUNDLE)
