// Free, no-card push sender — deploy to Vercel's Hobby tier.
//
// The app POSTs { idToken, code } here after a Common note is created. This
// verifies the caller, finds the partner's FCM tokens, and sends the push via
// Firebase Admin. Uses a service account (Firebase Console → Project settings →
// Service accounts → Generate new private key), stored as the Vercel env var
// FIREBASE_SERVICE_ACCOUNT (paste the whole JSON as the value).

const admin = require("firebase-admin");

function getApp() {
  if (admin.apps.length) return admin.app();
  const svc = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  return admin.initializeApp({credential: admin.credential.cert(svc)});
}

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({error: "POST only"});
  }
  try {
    const {idToken, code} = req.body || {};
    if (!idToken || !code) {
      return res.status(400).json({error: "missing idToken or code"});
    }

    const app = getApp();

    // Verify the caller is a signed-in user of this app.
    const decoded = await admin.auth(app).verifyIdToken(idToken);
    const authorUid = decoded.uid;

    const db = admin.firestore(app);

    const coupleSnap = await db.doc(`couples/${code}`).get();
    if (!coupleSnap.exists) return res.status(200).json({ok: true, note: "no couple"});
    const members = coupleSnap.data().members || [];
    if (!members.includes(authorUid)) {
      return res.status(403).json({error: "not a member of this couple"});
    }

    // Author display name.
    const authorSnap = await db.doc(`users/${authorUid}`).get();
    const authorName =
      (authorSnap.exists && authorSnap.data().displayName) || "Your partner";

    // Preview text from the most recent note.
    let preview = "New note";
    const notesSnap = await db
        .collection(`couples/${code}/notes`)
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();
    if (!notesSnap.empty) {
      const n = notesSnap.docs[0].data();
      preview = (n.text && n.text.length > 0) ?
        n.text :
        (n.imageId ? "📷 Photo" : "New note");
    }

    // Every member's token except the author's.
    const tokens = [];
    for (const uid of members) {
      if (uid === authorUid) continue;
      const us = await db.doc(`users/${uid}`).get();
      const t = (us.exists && us.data().fcmTokens) || [];
      tokens.push(...t);
    }
    if (tokens.length === 0) return res.status(200).json({ok: true, sent: 0});

    const resp = await admin.messaging(app).sendEachForMulticast({
      tokens,
      notification: {
        title: `💞 ${authorName} posted in Common`,
        body: preview.substring(0, 120),
      },
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });

    return res.status(200).json({ok: true, sent: resp.successCount});
  } catch (e) {
    console.error(e);
    return res.status(500).json({error: String(e && e.message || e)});
  }
};
