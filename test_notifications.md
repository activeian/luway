# 🧪 TEST PLAN PENTRU NOTIFICĂRI REALE

## **PROBLEMA IDENTIFICATĂ:**
- ✅ Notificările reale se înregistrează în aplicație 
- ✅ Push notifications pentru teste funcționează în buzunar
- ❌ Push notifications pentru notificările reale NU vin în buzunar

## **SOLUȚIA IMPLEMENTATĂ:**
1. `_sendPushNotification()` → `_sendRemotePushNotification()` → `_saveToPendingNotifications()`
2. Server Node.js procesează `pending_notifications` cu Firebase Admin SDK
3. Server trimite adevărate FCM push notifications

## **TESTE DE EFECTUAT:**

### 🔍 **TEST 1: Verifică dacă pending_notifications se creează**
1. Deschideți aplicația și mergeți la o conversație
2. Trimiteți un mesaj
3. Verificați în Firebase Console → Firestore → `pending_notifications`
4. **REZULTAT AȘTEPTAT:** Document nou cu `sent: false`

### 🔍 **TEST 2: Pornește serverul manual**
```bash
cd d:\LuWAy\luway\server
node server.js
```
**REZULTAT AȘTEPTAT:** "✅ Firebase Admin initialized successfully"

### 🔍 **TEST 3: Test push notification real**
1. Închideți aplicația complet
2. Puneți telefonul în buzunar/lock screen
3. De pe alt telefon, trimiteți un mesaj în chat
4. **REZULTAT AȘTEPTAT:** Push notification în buzunar

### 🔍 **TEST 4: Verifică token-ul FCM**
În NotificationService, să verificăm dacă `fcmToken` se obține corect:
```dart
static Future<String?> getFcmToken() async {
  final token = await _messaging.getToken();
  print('🔑 FCM Token: $token');
  return token;
}
```

## **DEBUG CHECKLIST:**
- [ ] Server rulează pe portul 3001
- [ ] `pending_notifications` se creează în Firestore  
- [ ] FCM token există și este valid
- [ ] Service account key e corect
- [ ] Firebase permissions sunt configurate
