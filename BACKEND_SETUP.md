# Website backend setup

The website continues to render its existing copy and locally bundled images by default. Firebase data is an optional live override: the first public website visit does not need a seeded Firestore document.

## Website Firebase configuration

1. Copy `.env.example` to `.env.local` at the project root.
2. Set the Firebase web app values and `VITE_MEDIA_API_URL` in `.env.local`, then run `npm install` and `npm run dev` or build the site.
3. Firebase web API keys and `VITE_` values are public client configuration. Do not put R2 credentials, service-account keys, or other private keys in these values.

## Firestore and admin access

1. Enable Google as a sign-in provider under Firebase Authentication > Sign-in method.
2. Add the website host to Firebase Authentication's authorized domains. For local testing, use `localhost`; for deployment, use the actual Firebase Hosting or custom domain.
3. Create Firebase Authentication accounts for the site owners.
4. For each owner, create `admins/{Firebase Auth UID}` in Firestore with a string field `email` exactly matching that user's Google account email.
5. Publish [firestore.rules](./firestore.rules) in the Firebase Console Rules editor. The rules allow public reads of the limited `site/adminPresence` status document and only admins to update it.
6. Install Flutter and, from `admin/`, generate platform folders with `flutter create --platforms=android,ios,web .` if they are not present. Keep the existing `lib/main.dart`, `pubspec.yaml`, and `web/index.html`. Add the Firebase Android and iOS app configuration files, then run `flutter pub get` from `admin/`. See [admin/README.md](./admin/README.md) for setup and browser testing instructions.

The `admins` collection is not writable by client apps. Firestore rules permit public reads only for `site/content`; authenticated owners can update that document after the UID/email allowlist check.

Customer chat uses Firebase Authentication's Google provider. Enable Google under Firebase Authentication > Sign-in method. Customers can sign in or create an account with the same Google button. Chat messages and conversations are protected by the Firestore rules in [firestore.rules](./firestore.rules). The admin app updates its presence heartbeat every 30 seconds; the website displays it as online only while that heartbeat is fresh. Admins can edit the public chat name and profile photo in the app; the values are stored as `profileName` and `profileImageUrl` on `site/adminPresence`.

The admin app writes optional overrides to `site/content`:

- `translations.en` / `translations.st`: website copy overrides
- `craftOverrides`: edited existing products keyed by their current product ID
- `newCrafts`: additional product records
- `images.hero`, `images.story`, `images.cta`, `images.showcase.*`, `images.process.*`: image URLs for section backgrounds and cards
- `contact`: phone, WhatsApp, email, and workshop address

Existing product data and assets are merged with overrides, so editing one item does not remove other products or local images.

## Cloudflare R2 image uploads

The R2 bucket `seithati-weavers-bucket` is accessed through a Cloudflare Worker binding. The S3-compatible endpoint and access keys are not needed for this binding, and no storage credentials are placed in either client app. Customer and admin chat images are stored under `customer-chat/{uid}/`; the Worker checks that the signed-in customer owns the room or that the caller is an authorized admin before upload or download. The admin app uses `/admin-chat-upload/{uid}` for staff attachments. Existing site and profile images uploaded by admins remain under `uploads/`.

1. Confirm the R2 bucket exists, then update `ALLOWED_ORIGINS` in [cloudflare/wrangler.toml](./cloudflare/wrangler.toml) to include the website's real HTTPS origin and any local development origins.
2. From the `cloudflare/` directory, authenticate Wrangler and deploy the Worker:

   ```sh
   npx wrangler login
   npx wrangler deploy
   ```

3. Set `VITE_MEDIA_API_URL` in the website's `.env.local` file to the deployed Worker base URL (for example, `https://YOUR-WORKER.workers.dev`). This is a public endpoint URL, not a secret.
4. Run/build the Flutter app with the deployed Worker URL:

   ```sh
   flutter run --dart-define=MEDIA_API_URL=https://YOUR-WORKER.workers.dev
   ```

The Worker checks Firebase ID tokens against Firestore before accepting admin uploads or serving customer chat media. It accepts JPEG, PNG, and WebP images up to 10 MB. The admin app's `/media/` route serves published site images; private chat attachments use authenticated `/chat-media/{uid}/{filename}` requests. Set the Worker URL as `MEDIA_API_URL` at Flutter build time.
