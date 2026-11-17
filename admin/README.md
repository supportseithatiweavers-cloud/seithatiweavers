# Seithati Weavers admin app

This Flutter app supports Android, iOS, and web. It signs in with Google and checks the signed-in Firebase user's UID and email against `admins/{uid}` before showing the management screens. Keep the existing website content and local images: website defaults remain active until an administrator publishes overrides.

## Set up Firebase

1. Install Flutter. From this `admin/` directory, generate platform folders with `flutter create --platforms=android,ios,web .` if they are missing (keep this app's `lib/main.dart`, `pubspec.yaml`, and `web/index.html`), then create Android and iOS app registrations for Firebase project `seithati-weavers`. Web uses the public Firebase web-app configuration already supplied for `seithati-weavers`.
2. Enable **Google** under Firebase Authentication > Sign-in method.
3. Add the Firebase native configuration files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
4. Configure the Google sign-in SHA fingerprints / iOS URL scheme as required by Firebase, then run `flutter pub get`.
5. In Firebase Authentication, create or invite the owner Google accounts. Copy each user's Firebase Auth **UID** and exact email into a Firestore document at `admins/{uid}` with field `email` set to that email.
6. Publish the repository's `firestore.rules` to the project's Firestore database.
7. Add `localhost` and the deployed admin website's domain to Firebase Authentication > Settings > Authorized domains. Web Google sign-in uses Firebase Authentication's popup.

For iOS photo uploads, add an `NSPhotoLibraryUsageDescription` entry to `ios/Runner/Info.plist` describing that owners use the photo library to publish website images.

The app intentionally cannot create admin allowlist entries. Add owners in Firebase Console so an authenticated user cannot grant themselves access.

## Configure image uploads

Deploy `cloudflare/worker.js` with `cloudflare/wrangler.toml` and the configured R2 bucket binding. Set `ALLOWED_ORIGINS` to include the deployed admin website origin. Local development origins on ports 5173, 5000, and 8080 are pre-listed. The Worker uses the R2 binding for image uploads and serving. No storage credentials are embedded in this app.

Build or run the Flutter app with the deployed Worker URL:

```sh
flutter run --dart-define=MEDIA_API_URL=https://YOUR-WORKER.workers.dev
```

## Run the admin app in a browser

From `admin/`, after generating the web platform folder and installing packages:

```sh
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=MEDIA_API_URL=https://YOUR-WORKER.workers.dev
```

The web build initializes Firebase from the public web app configuration supplied for this project. Allow the Google sign-in popup for localhost. Browser image uploads also require the local origin to be listed in `ALLOWED_ORIGINS` and the Worker to be deployed.

To produce a deployable web build:

```sh
flutter build web --dart-define=MEDIA_API_URL=https://YOUR-WORKER.workers.dev
```

Only the Worker URL is a client setting; it is not a credential. Firebase web/native configuration is also public client configuration. Never put Cloudflare R2 access keys, Firebase service-account keys, or other server secrets in Flutter, the website bundle, or a `VITE_` variable.

## Content behavior

The manager edits English and Sesotho website text (including additional translation keys), product details, section/product images, and contact information in `site/content`. The existing site copy and imported images remain as fallback defaults. New images are uploaded to the bound R2 bucket and their public Worker URLs are saved in Firestore.
