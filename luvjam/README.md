# LuvJam - How to Run the Application

## 1. Install the Required Tools

- Install Flutter and add its `bin` directory to your system PATH.
- Install Visual Studio Code.
- Install the Android SDK and required build tools.
- Connect an Android phone with USB debugging enabled if you want to install directly.

Check your setup:

```sh
flutter doctor
```

Resolve any issues required for your target platform before continuing.

## 2. Open the Project

Open the LuvJam project folder in VS Code.

In the terminal, navigate to the folder containing `pubspec.yaml`:

```sh
cd C:\tinoortega-bmc\luvjam
```

## 3. Install Dependencies

Download the required Flutter packages:

```sh
flutter pub get
```

## 4. Configure Supabase

Configure the Supabase URL and publishable key required by the application.

If using the `.env` file with `flutter_dotenv`, make sure it contains:

```text
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_publishable_key
```

Make sure `.env` is included in the Flutter assets in `pubspec.yaml` and loaded before `Supabase.initialize()` in `main.dart`.

Use only a Supabase publishable key or legacy anon key in the Flutter application. Never put Supabase secret keys or Xendit secret keys in client-side assets.

## 5. Start a Device

List the available devices:

```sh
flutter devices
```

Connect your Android phone with USB debugging enabled, or use an available emulator.

## 6. Run the Application

To run LuvJam in Microsoft Edge:

```sh
flutter run -d edge
```

To run it on a connected Android device:

```sh
flutter run
```

If the project uses a `.env` file, ensure it is configured and loaded before running the app.

## 7. Register and Log In

1. Open LuvJam.
2. Register a new account or use an existing account.
3. Log in with the registered credentials.
4. Browse the available clothing products.

An internet connection is required for Supabase-backed features.

## 8. Build the Android APK

From the project root, run:

```sh
flutter build apk --release
```

Wait for the build to complete successfully.

The generated APK is located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 9. Install Directly on a Connected Android Device

Connect your phone with USB debugging enabled, then run:

```sh
flutter install --release
```

If multiple devices are connected, specify the device ID:

```sh
flutter install --release -d DEVICE_ID
```

Replace `DEVICE_ID` with the ID shown by `flutter devices`.

## 10. Share and Install the APK

1. Upload `app-release.apk` to Google Drive.
2. Download the APK on the Android phone.
3. Open the downloaded file.
4. Allow installation from that source if Android requests permission.
5. Tap Install, then Open.

To update an existing installation, the new APK must use the same application ID and compatible signing key.

## 11. Payment Configuration

If Xendit payments are enabled, the payment backend must be configured correctly.

- Keep the Xendit secret key on the backend.
- Configure the payment callback token on the backend.
- Ensure the payment endpoint and webhook are working before testing checkout.

The Flutter application should never contain Xendit secret credentials.

## Troubleshooting

- **Flutter command not found:** Check that the Flutter `bin` directory is added to PATH.
- **Dependency errors:** Run `flutter pub get` again.
- **No device found:** Run `flutter devices` and check the USB debugging connection.
- **Supabase connection errors:** Verify the project URL, publishable key, and database access policies.
- **APK installation errors:** Confirm that the APK built successfully and is compatible with the device.
- **Payment errors:** Verify the backend payment endpoint and Xendit webhook configuration.
