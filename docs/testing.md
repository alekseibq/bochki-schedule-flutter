# Testing

## Automated Coverage

- `melos run test` покрывает unit и widget tests по всему workspace.
- `melos run app-test-integration-linux` прогоняет integration test для desktop shell на Linux.
- В GitHub Actions desktop integration дополнительно гоняется на Windows.

## Windows Smoke Checklist

Use this checklist on the developer Windows machine after building or running the desktop app.

1. Start the desktop application.
2. Verify that the main window opens with the title `ПО Расписание Бочки`.
3. Verify that the window can be resized and does not collapse below the intended minimum layout.
4. Open the `Справочники` menu in the header.
5. Select `Тренеры` and verify that the trainers placeholder screen is shown.
6. Open `Справочники` again, select `Участники`, and verify that the participants placeholder screen is shown.
7. Verify that the application stays responsive and does not crash during those actions.

## Linux Integration Prerequisites

For local Linux desktop integration runs, install:

- `clang`
- `cmake`
- `ninja-build`
- `pkg-config`
- `libgtk-3-dev`
