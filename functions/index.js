// Cloud Function: notify the other partner when a note is added to the shared
// Common feed. Deploy with:  firebase deploy --only functions
//
// Requires the Blaze (pay-as-you-go) plan. Free tier covers small usage.

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.notifyPartnerOnNote = onDocumentCreated(
    "couples/{code}/notes/{noteId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;

      const note = snap.data();
      const code = event.params.code;
      const authorUid = note.authorUid || null;
      const author = note.author || "Your partner";
      const preview = (note.text && note.text.length > 0) ?
        note.text :
        (note.imageId ? "📷 Photo" : "New note");

      const db = getFirestore();
      const coupleSnap = await db.collection("couples").doc(code).get();
      const members = (coupleSnap.exists && coupleSnap.data().members) || [];

      // Collect the FCM tokens of every member who is NOT the author.
      const tokens = [];
      const tokenOwner = {};
      for (const uid of members) {
        if (uid === authorUid) continue;
        const userSnap = await db.collection("users").doc(uid).get();
        const userTokens = (userSnap.exists && userSnap.data().fcmTokens) || [];
        for (const t of userTokens) {
          tokens.push(t);
          tokenOwner[t] = uid;
        }
      }
      if (tokens.length === 0) return;

      const res = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: `💞 ${author} posted in Common`,
          body: preview.substring(0, 120),
        },
        android: {priority: "high"},
        apns: {payload: {aps: {sound: "default"}}},
      });

      // Clean up tokens that are no longer valid.
      const stale = [];
      res.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error && r.error.code;
          if (code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token") {
            stale.push(tokens[i]);
          }
        }
      });
      const byUser = {};
      for (const t of stale) {
        (byUser[tokenOwner[t]] = byUser[tokenOwner[t]] || []).push(t);
      }
      for (const uid of Object.keys(byUser)) {
        await db.collection("users").doc(uid).set(
            {fcmTokens: FieldValue.arrayRemove(...byUser[uid])},
            {merge: true},
        );
      }
    },
);
