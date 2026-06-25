SHELL := powershell.exe
.SHELLFLAGS := -NoLogo -NoProfile -ExecutionPolicy Bypass -Command
.ONESHELL:

WINDOWS_APP_DIR := packages/bochki_schedule_app
WINDOWS_RELEASE_DIR := $(WINDOWS_APP_DIR)/build/windows/x64/runner/Release
WINDOWS_RELEASE_ZIP := bochki_schedule_app-windows-release.zip

.PHONY: windows-release
windows-release:
	Set-Location "$(WINDOWS_APP_DIR)"
	flutter config --enable-windows-desktop
	flutter build windows --release
	Set-Location "$(WINDOWS_RELEASE_DIR)"
	if (Test-Path "$(WINDOWS_RELEASE_ZIP)") { Remove-Item "$(WINDOWS_RELEASE_ZIP)" -Force }
	Compress-Archive -Path * -DestinationPath "$(WINDOWS_RELEASE_ZIP)" -Force
