const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
let db, messaging;
let firebaseInitialized = false;

try {
  let serviceAccount;
  try {
    serviceAccount = require('./service-account-key.json');
    console.log('✅ Service account key found');
  } catch (e) {
    console.warn('⚠️ Service account key not found, running in demo mode');
    serviceAccount = null;
  }
  
  if (serviceAccount && serviceAccount.private_key && serviceAccount.private_key !== "-----BEGIN PRIVATE KEY-----\nTEST_PRIVATE_KEY\n-----END PRIVATE KEY-----\n") {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id
    });
    
    db = admin.firestore();
    messaging = admin.messaging();
    firebaseInitialized = true;
    console.log('✅ Firebase Admin initialized successfully');
  } else {
    console.log('📝 Running in demo mode without Firebase Admin');
  }
} catch (error) {
  console.error('❌ Error initializing Firebase Admin:', error);
  console.log('📝 Running in demo mode without Firebase Admin');
}

// Notification service functions
class NotificationServer {
  
  // Send pending notifications
  static async sendPendingNotifications() {
    try {
      console.log('🔔 Checking for pending notifications...');
      
      if (!firebaseInitialized || !db) {
        console.log('⚠️ Firebase not initialized, skipping notification check');
        return;
      }
      
      const pendingQuery = await db.collection('pending_notifications')
        .where('sent', '==', false)
        .limit(parseInt(process.env.MAX_NOTIFICATIONS_PER_BATCH) || 100)
        .get();

      if (pendingQuery.empty) {
        console.log('📭 No pending notifications found');
        return;
      }

      console.log(`📨 Found ${pendingQuery.docs.length} pending notifications`);
      
      const batch = db.batch();
      let successCount = 0;
      let errorCount = 0;

      for (const doc of pendingQuery.docs) {
        const data = doc.data();
        
        try {
          if (!messaging) {
            console.log('⚠️ Messaging service not available, marking as failed');
            batch.update(doc.ref, { 
              sent: true, 
              sentAt: admin.firestore.FieldValue.serverTimestamp(),
              status: 'failed',
              error: 'Messaging service not available'
            });
            errorCount++;
            continue;
          }

          const message = {
            token: data.token,
            notification: {
              title: data.title,
              body: data.body,
            },
            data: this.convertDataToStrings(data.data || {}),
            android: {
              notification: {
                sound: 'default',
                channelId: this.getChannelId(data.data?.type),
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          };

          await messaging.send(message);
          
          // Mark as sent
          batch.update(doc.ref, { 
            sent: true, 
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'success'
          });
          
          successCount++;
          console.log(`✅ Notification sent to token: ${data.token.substring(0, 20)}...`);
          
        } catch (error) {
          console.error(`❌ Error sending notification to ${data.token.substring(0, 20)}...:`, error.message);
          
          // Mark as failed
          batch.update(doc.ref, { 
            sent: true, 
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'failed',
            error: error.message
          });
          
          errorCount++;
        }
      }

      await batch.commit();
      console.log(`📊 Notification batch completed: ${successCount} sent, ${errorCount} failed`);
      
    } catch (error) {
      console.error('❌ Error in sendPendingNotifications:', error);
    }
  }

  // Convert all data values to strings (FCM requirement)
  static convertDataToStrings(data) {
    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
      stringData[key] = String(value);
    }
    return stringData;
  }

  // Get notification channel ID based on type
  static getChannelId(type) {
    switch (type) {
      case 'message':
        return 'messages';
      case 'favorite_added':
        return 'favorites';
      case 'price_update':
        return 'price_updates';
      case 'daily_summary':
        return 'daily_summary';
      default:
        return 'default';
    }
  }

  // Send daily summary notifications
  static async sendDailySummary() {
    try {
      console.log('📊 Starting daily summary notifications...');
      
      if (!firebaseInitialized || !db) {
        console.log('⚠️ Firebase not initialized, skipping daily summary');
        return;
      }
      
      const today = new Date();
      const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const endOfDay = new Date(startOfDay);
      endOfDay.setDate(endOfDay.getDate() + 1);

      // Get all users
      const usersQuery = await db.collection('users').get();
      let summariesSent = 0;

      for (const userDoc of usersQuery.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        
        if (!userData.fcmToken) continue;

        try {
          // Get user's marketplace items
          const userItemsQuery = await db.collection('marketplace')
            .where('sellerId', '==', userId)
            .get();

          if (userItemsQuery.empty) continue;

          const itemIds = userItemsQuery.docs.map(doc => doc.id);
          
          // Count today's favorites for user's items
          let totalFavorites = 0;
          const favoritedItems = [];

          for (const itemId of itemIds) {
            const favoritesQuery = await db.collection('favorites')
              .where('itemId', '==', itemId)
              .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
              .where('timestamp', '<', admin.firestore.Timestamp.fromDate(endOfDay))
              .get();

            if (!favoritesQuery.empty) {
              totalFavorites += favoritesQuery.docs.length;
              
              // Get item title
              const itemDoc = userItemsQuery.docs.find(doc => doc.id === itemId);
              if (itemDoc) {
                favoritedItems.push(itemDoc.data().title || 'Listing');
              }
            }
          }

          // Send notification only if there are favorites
          if (totalFavorites > 0) {
            const body = totalFavorites === 1 
              ? 'One person added your listings to favorites today'
              : `${totalFavorites} people added your listings to favorites today`;

            await db.collection('pending_notifications').add({
              token: userData.fcmToken,
              title: 'Daily summary',
              body: body,
              data: {
                type: 'daily_summary',
                totalFavorites: totalFavorites.toString(),
                itemTitles: favoritedItems.join(','),
              },
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              sent: false,
            });

            summariesSent++;
            console.log(`📊 Daily summary queued for user ${userId}: ${totalFavorites} favorites`);
          }
        } catch (error) {
          console.error(`❌ Error processing daily summary for user ${userId}:`, error);
        }
      }

      console.log(`✅ Daily summary completed: ${summariesSent} notifications queued`);
      
    } catch (error) {
      console.error('❌ Error in sendDailySummary:', error);
    }
  }

  // Clean old notifications
  static async cleanOldNotifications() {
    try {
      console.log('🧹 Cleaning old notifications...');
      
      if (!firebaseInitialized || !db) {
        console.log('⚠️ Firebase not initialized, skipping cleanup');
        return;
      }
      
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const oldNotificationsQuery = await db.collection('pending_notifications')
        .where('timestamp', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .limit(500)
        .get();

      if (oldNotificationsQuery.empty) {
        console.log('📭 No old notifications to clean');
        return;
      }

      const batch = db.batch();
      oldNotificationsQuery.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`🗑️ Cleaned ${oldNotificationsQuery.docs.length} old notifications`);
      
    } catch (error) {
      console.error('❌ Error cleaning old notifications:', error);
    }
  }
}

// API Endpoints
app.get('/', (req, res) => {
  res.json({
    message: 'LuWay Notification Server',
    status: 'running',
    firebase: firebaseInitialized ? 'connected' : 'demo-mode',
    endpoints: ['/health', '/send-pending', '/send-daily-summary', '/test-notification']
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'LuWay Notification Server',
    firebase: firebaseInitialized ? 'connected' : 'demo-mode'
  });
});

// Manual trigger for pending notifications
app.post('/send-pending', async (req, res) => {
  try {
    await NotificationServer.sendPendingNotifications();
    res.json({ success: true, message: 'Pending notifications processed' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Manual trigger for daily summary
app.post('/send-daily-summary', async (req, res) => {
  try {
    await NotificationServer.sendDailySummary();
    res.json({ success: true, message: 'Daily summary notifications queued' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Send test notification
app.post('/test-notification', async (req, res) => {
  try {
    const { token, title, body } = req.body;
    
    if (!token || !title || !body) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: token, title, body' 
      });
    }

    if (!messaging) {
      return res.status(500).json({
        success: false,
        error: 'Messaging service not available - Firebase not properly initialized'
      });
    }

    const message = {
      token,
      notification: { title, body },
      data: { type: 'test' },
      android: {
        notification: {
          sound: 'default',
          channelId: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    await messaging.send(message);
    res.json({ success: true, message: 'Test notification sent' });
    
  } catch (error) {
    console.error('❌ Test notification error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get FCM token for user testing
app.post('/get-user-token', async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing userId' 
      });
    }

    if (!firebaseInitialized || !db) {
      return res.status(500).json({
        success: false,
        error: 'Firebase database not available'
      });
    }

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      return res.status(404).json({
        success: false,
        error: 'No FCM token found for user'
      });
    }

    res.json({ 
      success: true, 
      token: fcmToken.substring(0, 20) + '...', // Partial token for security
      fullToken: fcmToken // For testing only - remove in production
    });
    
  } catch (error) {
    console.error('❌ Error getting user token:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Trigger price update notification test
app.post('/test-price-update', async (req, res) => {
  try {
    const { itemId, oldPrice, newPrice } = req.body;
    
    if (!itemId || oldPrice === undefined || newPrice === undefined) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: itemId, oldPrice, newPrice' 
      });
    }

    if (!firebaseInitialized || !db) {
      return res.status(500).json({
        success: false,
        error: 'Firebase database not available'
      });
    }

    // Get the marketplace item
    const itemDoc = await db.collection('marketplace').doc(itemId).get();
    if (!itemDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Marketplace item not found'
      });
    }

    const itemData = itemDoc.data();
    const itemTitle = itemData.title || 'Unknown Item';

    // Get users who favorited this item
    const favoritesQuery = await db.collection('favorites')
      .where('itemId', '==', itemId)
      .get();

    if (favoritesQuery.empty) {
      return res.json({
        success: true,
        message: 'No users have favorited this item',
        notificationsSent: 0
      });
    }

    let notificationsSent = 0;

    // Send notification to each user who favorited the item
    for (const favDoc of favoritesQuery.docs) {
      const userId = favDoc.data().userId;
      if (!userId) continue;

      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;
      
      if (!fcmToken) continue;

      const priceChange = newPrice < oldPrice ? 'decreased' : 'increased';
      const priceDiff = Math.abs(newPrice - oldPrice);

      await db.collection('pending_notifications').add({
        token: fcmToken,
        title: 'Price updated!',
        body: `Price for "${itemTitle}" has ${priceChange} by €${priceDiff.toFixed(0)}`,
        data: {
          type: 'price_update',
          itemId: itemId,
          oldPrice: oldPrice.toString(),
          newPrice: newPrice.toString(),
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
      });

      notificationsSent++;
    }

    res.json({ 
      success: true, 
      message: `Price update notifications queued for ${notificationsSent} users`,
      notificationsSent: notificationsSent
    });
    
  } catch (error) {
    console.error('❌ Test price update error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Scheduled tasks
console.log('⏰ Setting up scheduled tasks...');

// Check for pending notifications every 30 seconds
cron.schedule('*/30 * * * * *', () => {
  NotificationServer.sendPendingNotifications();
});

// Send daily summary at 8 PM every day
const dailySummaryHour = process.env.DAILY_SUMMARY_HOUR || 20;
cron.schedule(`0 0 ${dailySummaryHour} * * *`, () => {
  NotificationServer.sendDailySummary();
});

// Clean old notifications every day at 2 AM
cron.schedule('0 0 2 * * *', () => {
  NotificationServer.cleanOldNotifications();
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 LuWay Notification Server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase: ${firebaseInitialized ? 'Connected' : 'Demo Mode'}`);
  console.log(`🔔 Notification check interval: every 30 seconds`);
  console.log(`📊 Daily summary time: ${dailySummaryHour}:00`);
  console.log(`🧹 Old notifications cleanup: daily at 2:00 AM`);
  
  // Send initial pending notifications only if Firebase is connected
  if (firebaseInitialized) {
    setTimeout(() => {
      NotificationServer.sendPendingNotifications();
    }, 5000);
  } else {
    console.log('⚠️ Running in demo mode - notifications disabled');
  }
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('🛑 Shutting down notification server...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('🛑 Shutting down notification server...');
  process.exit(0);
});