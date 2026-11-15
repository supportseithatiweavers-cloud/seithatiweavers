# Website backend setup

The website continues to render its existing copy and locally bundled images by default. Firebase data is an optional live override: the first public website visit does not need a seeded Firestore document.

## Website Firebase configuration

1. Copy `.env.example` to `.env.local` at the project root.
2. Keep the Firebase web app configuration values in `.env.local`, then run `npm install` and `npm run dev` or build the site.
3. Firebase web API keys and `VITE_` values are public client configuration. Do not put R2 credentials, service-account keys, or other private keys in these values.

## Firestore and admin access

1. Enable Google as a sign-in provider under Firebase Authentication > Sign-in method.
2. Create Firebase Authentication accounts for the site owners.
3. For each owner, create `admins/{Firebase Auth UID}` in Firestore with a string field `email` exactly matching that user's Google account email.
4. Publish [firestore.rules](./firestore.rules) in the Firebase Console Rules editor.
5. Install Flutter and, from `admin/`, generate platform folders with `flutter create --platforms=android,ios,web .` if they are not present. Keep the existing `lib/main.dart`, `pubspec.yaml`, and `web/index.html`. Add the Firebase Android and iOS app configuration files, then run `flutter pub get` from `admin/`. See [admin/README.md](./admin/README.md) for setup and browser testing instructions.

The `admins` collection is not writable by client apps. Firestore rules permit public reads only for `site/content`; authenticated owners can update that document after the UID/email allowlist check.

The admin app writes optional overrides to `site/content`:

- `translations.en` / `translations.st`: website copy overrides
- `craftOverrides`: edited existing products keyed by their current product ID
- `newCrafts`: additional product records
- `images.hero`, `images.story`, `images.cta`, `images.showcase.*`, `images.process.*`: image URLs for section backgrounds and cards
- `contact`: phone, WhatsApp, email, and workshop address

Existing product data and assets are merged with overrides, so editing one item does not remove other products or local images.

## Cloudflare R2 image uploads

The R2 bucket `seithati-weavers-bucket` is accessed through a Cloudflare Worker binding. The S3-compatible endpoint and access keys are not needed for this binding, and no storage credentials are placed in either client app.

1. Confirm the R2 bucket exists, then update `ALLOWED_ORIGINS` in [cloudflare/wrangler.toml](./cloudflare/wrangler.toml) to include the website's real HTTPS origin and any local Flutter web development origin.
2. From the `cloudflare/` directory, authenticate Wrangler and deploy the Worker:

   ```sh
   npx wrangler login
   npx wrangler deploy
   ```

3. Run/build the Flutter app with the deployed Worker URL:

   ```sh
   flutter run --dart-define=MEDIA_API_URL=https://YOUR-WORKER.workers.dev
   ```

The Worker checks the Firebase ID token against the caller's own `admins/{uid}` document before accepting uploads. It accepts JPEG, PNG, and WebP files up to 10 MB, stores images in the bound R2 bucket, and serves them from its `/media/` route. Set the Worker URL as `MEDIA_API_URL` at build time; it is an endpoint, not a secret.
