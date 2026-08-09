# sisi notes — free push sender (Vercel, no card)

Sends the "💞 partner posted in Common" push without needing the Firebase Blaze
plan or a billing card. Hosted on Vercel's free Hobby tier.

## One-time setup

1. **Get a service account key**
   Firebase Console → ⚙ Project settings → **Service accounts** →
   **Generate new private key** → downloads a JSON file. Open it and copy the
   whole contents.

2. **Create the Vercel project** (free, no card — sign in with GitHub)
   - Push this `push_server/` folder to a GitHub repo (or use `vercel` CLI).
   - On [vercel.com](https://vercel.com) → **Add New → Project** → import it.

3. **Add the secret**
   Vercel project → **Settings → Environment Variables** → add:
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: *(paste the entire service-account JSON from step 1)*
   Then **redeploy**.

4. **Copy your endpoint URL**
   It's `https://<your-project>.vercel.app/api/notify`.

5. **Tell the app about it**
   In `lib/services/push_sender.dart`, set:
   ```dart
   static const String _endpoint = 'https://<your-project>.vercel.app/api/notify';
   ```
   Rebuild the app.

## Notes
- **Android** push works immediately after this.
- **iOS** push still needs an APNs key uploaded in Firebase → Cloud Messaging
  (requires a Mac / Apple Developer account).
- No Blaze, no billing card. Vercel Hobby + Firebase Spark are both free.
- The `functions/` folder (Firebase Cloud Function) is the *alternative* Blaze
  approach; you don't need it if you use this.
