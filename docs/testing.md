# Testing

## Automated Coverage

- `melos run test` покрывает unit и widget tests по всему workspace.
- `melos run app-test-integration-linux` прогоняет integration test для desktop shell на Linux.
- В GitHub Actions desktop integration дополнительно гоняется на Windows.
- В Windows job CI после сборки публикуется ZIP artifact с release-папкой.

## Windows Release Build

На Windows-машине для локальной сборки release-артефакта используйте:

```bash
make windows-release
```

Команда включает Windows desktop target, собирает `flutter build windows --release` и кладет ZIP рядом с release-папкой:

- `packages/bochki_schedule_app/build/windows/x64/runner/Release/bochki_schedule_app-windows-release.zip`

## Windows Smoke Checklist

Use this checklist on the developer Windows machine after building or running the desktop app.

1. Start the desktop application.
2. Verify that the main window opens with the title `ПО Расписание Бочки`.
3. Verify that the window can be resized and does not collapse below the intended minimum layout.

4. Open the `Справочники` menu in the header.
5. Select `Ассистенты` and verify that the assistants dialog is shown.
6. Verify that the assistants dialog supports create, edit, and delete for assistant rows.
7. Open `Справочники` again, select `Участники`, and verify that the participants dialog is shown.
8. Verify that the participants dialog contains the participant name field and the add/edit/delete controls.
9. Verify that the application stays responsive and does not crash during those actions.

## Nested Windows Smoke Checklist

Run this check on both Windows and macOS:

1. Open a directory window and then its editor window.
2. Switch to another application, then return to the editor window.
3. Close the editor with the system close button; verify that the directory window is shown and focused.
4. Repeat using Cancel and a successful save; verify the same focus result.
5. With the editor open, close the directory window with the system close button; verify that the editor closes too, without reactivating the directory.
6. Move the parent window to a secondary monitor, then open each child-window type; verify that it first appears once, centered on that monitor, without a flash at the top-left corner.

## Linux Integration Prerequisites

For local Linux desktop integration runs, install:

- `clang`
- `cmake`
- `ninja-build`
- `pkg-config`
- `libgtk-3-dev`

## Desktop Launch Path

When the app is launched without arguments, Windows stores `project.json` next to the launched binary.
On macOS, it stores `project.json` in the app's Application Support directory inside the sandbox container.
For CI or local smoke runs, pass `--app-data-dir=<path>` so the app writes into an explicit temporary directory.

## macOS Release Artifacts

Release tags publish two separate macOS zips:

- `bochki_schedule_app-macos-intel-release.zip` for Intel Macs
- `bochki_schedule_app-macos-arm64-release.zip` for Apple Silicon Macs
