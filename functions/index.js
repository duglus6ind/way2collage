const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendBusStatusNotification = functions.firestore
    .document("Buses/{busId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Only trigger if status changed
      if (before.status === after.status) {
        return null;
      }

      const busId = context.params.busId;
      const status = after.status;
      const delayMinutes = after.delayMinutes || "";
      const delayReason = after.delayReason || "";

      let messageBody = "";

      if (status === "DELAYED") {
        messageBody = `Bus delayed ${delayMinutes} mins. ${delayReason}`;
      } else if (status === "BREAKDOWN") {
        messageBody = "Bus breakdown. Please wait for updates.";
      } else {
        messageBody = "Bus is on the way.";
      }

      // 🔎 Find students assigned to this bus
      const usersSnapshot = await admin.firestore()
          .collection("Users")
          .where("AssignedBusId", "==", busId)
          .get();

      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        return null;
      }

      const payload = {
        notification: {
          title: "Bus Status Update",
          body: messageBody,
        },
        android: {
          notification: {
            channelId: "bus_channel",
          },
        },
      };

      await admin.messaging().sendToDevice(tokens, payload);

      return null;
    });

exports.sendPushNotificationOnNewDoc = functions.firestore
    .document("Notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notificationData = snap.data();
      const toUserId = notificationData.toUserId;
      const title = notificationData.title || "New Notification";
      const message = notificationData.message || "";

      if (!toUserId) {
        console.log("No toUserId found in notification.");
        return null;
      }

      // Fetch user to get fcmToken
      const userDoc = await admin.firestore()
          .collection("Users")
          .doc(toUserId)
          .get();

      if (!userDoc.exists) {
        console.log(`User ${toUserId} does not exist.`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`User ${toUserId} has no FCM token.`);
        return null;
      }

      const payload = {
        notification: {
          title: title,
          body: message,
        },
        android: {
          notification: {
            channelId: "bus_channel",
          },
        },
      };

      try {
        await admin.messaging().sendToDevice(fcmToken, payload);
        console.log(`Successfully sent push notification to ${toUserId}`);
      } catch (error) {
        console.error("Error sending push notification:", error);
      }

      return null;
    });
