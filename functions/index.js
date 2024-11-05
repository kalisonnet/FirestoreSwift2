/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onValueWritten} = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Function to send notifications when an order is assigned
exports.sendOrderAssignmentNotification = onValueWritten(
    {ref: "/orders/{orderId}/phlebotomist"},
    async (event) => {
      const orderId = event.params.orderId;
      const newPhlebotomistIds = event.data.after.val();

      if (!newPhlebotomistIds) {
        logger.info(`No phlebotomists assigned for order ${orderId}`);
        return null;
      }

      try {
      // Retrieve the FCM tokens of the assigned users (phlebotomists)
        const getUserPromises = newPhlebotomistIds.map((phlebotomistId) =>
          admin.database().ref(`/users/${phlebotomistId}`).once("value"),
        );

        const userSnapshots = await Promise.all(getUserPromises);
        const tokens = userSnapshots
            .map((snapshot) => snapshot.val().fcmToken)
            .filter(Boolean); // Filter out null or undefined tokens

        if (tokens.length === 0) {
          logger.info("No tokens available for notification.");
          return null;
        }

        // Prepare the notification payload
        const payload = {
          notification: {
            title: "New Order Assigned",
            body: `You have been assigned a new order (ID: ${orderId})`,
            sound: "default",
          },
        };

        // Send the notification to the phlebotomists' devices
        const response = await admin.messaging().sendToDevice(tokens, payload);
        logger.info("Successfully sent notifications:", response);
      } catch (error) {
        logger.error("Error sending notifications:", error);
      }
      return null;
    },
);


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
