# 🔐 Firebase Firestore Security Rules - LuWAy

## 📋 Reguli Complete pentru Sistemul de Notificări și Mesagerie

Aceste reguli trebuie adăugate în Firebase Console → Firestore Database → Rules.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== UTILIZATORI =====
    match /users/{userId} {
      // Utilizatorii pot citi și scrie doar propriile date
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Permitem citirea publică pentru nickname, displayName, isOnline, lastSeen (pentru chat)
      allow read: if request.auth != null && 
        resource.data.keys().hasOnly(['nickname', 'displayName', 'isOnline', 'lastSeen', 'fcmToken']);
    }
    
    // ===== CONVERSAȚII =====
    match /conversations/{conversationId} {
      // Doar participanții pot accesa conversația
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      // Permite crearea unei conversații noi dacă user-ul e în participanți
      allow create: if request.auth != null && 
        request.auth.uid in request.resource.data.participants;
      
      // ===== MESAJE DIN CONVERSAȚII =====
      match /messages/{messageId} {
        // Doar participanții conversației pot vedea mesajele
        allow read: if request.auth != null && 
          (request.auth.uid == resource.data.senderId || 
           request.auth.uid == resource.data.receiverId);
        
        // Doar expeditorul poate crea mesajul
        allow create: if request.auth != null && 
          request.auth.uid == request.resource.data.senderId;
        
        // Doar destinatarul poate marca ca citit
        allow update: if request.auth != null && 
          request.auth.uid == resource.data.receiverId &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
        
        // Doar expeditorul poate șterge propriile mesaje
        allow delete: if request.auth != null && 
          request.auth.uid == resource.data.senderId;
      }
    }
    
    // ===== NOTIFICĂRI =====
    match /users/{userId}/notifications/{notificationId} {
      // Doar proprietarul poate accesa propriile notificări
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Server-ul poate crea notificări (prin service account)
      allow create: if true; // Serverul folosește service account cu permisiuni admin
    }
    
    // ===== MARKETPLACE =====
    match /marketplace/{itemId} {
      // Toată lumea poate citi anunțurile publice
      allow read: if true;
      
      // Doar proprietarul poate modifica anunțul
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.ownerId;
      
      // Utilizatorii autentificați pot crea anunțuri noi
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.ownerId;
    }
    
    // ===== FAVORITE =====
    match /users/{userId}/favorites/{favoriteId} {
      // Doar proprietarul poate accesa propriile favorite
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ===== FAVORITE GLOBALE (pentru notificări) =====
    match /favorites/{favoriteId} {
      // Toată lumea poate citi pentru a afla cine a adăugat la favorite
      allow read: if request.auth != null;
      
      // Doar utilizatorul poate adăuga/șterge propriile favorite
      allow create, delete: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
    
    // ===== ISTORIC PREȚURI =====
    match /price_history/{historyId} {
      // Toată lumea poate citi istoricul prețurilor
      allow read: if true;
      
      // Doar sistemul poate scrie (prin cloud functions sau server)
      allow write: if false; // Doar server-ul cu service account
    }
    
    // ===== NOTIFICĂRI PENDING (pentru server) =====
    match /pending_notifications/{notificationId} {
      // Doar sistemul poate accesa (prin service account)
      allow read, write: if false; // Doar server-ul cu service account
    }
    
    // ===== TASK-URI PROGRAMATE =====
    match /scheduled_tasks/{taskId} {
      // Doar sistemul poate accesa (prin service account)
      allow read, write: if false; // Doar server-ul cu service account
    }
    
    // ===== ANALYTICS/STATISTICI =====
    match /analytics/{analyticsId} {
      // Utilizatorii pot citi propriile statistici
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      
      // Doar sistemul poate scrie statistici
      allow write: if false; // Doar server-ul cu service account
    }
    
    // ===== FUNCȚII HELPER =====
    
    // Verifică dacă utilizatorul poate accesa o conversație
    function canAccessConversation(conversationId) {
      return request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
    }
    
    // Verifică dacă utilizatorul e proprietarul unui anunț
    function isItemOwner(itemId) {
      return request.auth != null && 
        request.auth.uid == get(/databases/$(database)/documents/marketplace/$(itemId)).data.ownerId;
    }
    
    // Verifică dacă datele sunt valide pentru un mesaj
    function isValidMessage(data) {
      return data.keys().hasAll(['senderId', 'receiverId', 'message', 'timestamp']) &&
        data.senderId == request.auth.uid &&
        data.message is string &&
        data.timestamp is timestamp;
    }
    
    // Verifică dacă datele sunt valide pentru o notificare
    function isValidNotification(data) {
      return data.keys().hasAll(['title', 'body', 'type', 'timestamp', 'read']) &&
        data.title is string &&
        data.body is string &&
        data.type in ['message', 'favorite_added', 'price_update', 'daily_summary'] &&
        data.timestamp is timestamp &&
        data.read is bool;
    }
  }
}
```

## 🔧 Reguli Speciale pentru Dezvoltare

Când testezi aplicația în development, poți folosi reguli mai permisive:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ATENȚIE: Folosește doar pentru dezvoltare!
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📝 Explicații pentru Reguli

### 🔐 Principii de Securitate

1. **Autentificare Obligatorie**: Majoritatea operațiilor necesită utilizator autentificat
2. **Proprietate**: Utilizatorii pot accesa doar propriile date
3. **Participare**: În conversații, doar participanții au acces
4. **Citire Publică Limitată**: Anunțurile sunt publice, dar datele personale nu
5. **Server Access**: Unele colecții sunt accesibile doar serverului cu service account

### 📱 Reguli per Funcționalitate

#### Mesagerie
- Doar participanții conversației pot vedea mesajele
- Doar expeditorul poate trimite mesaje
- Doar destinatarul poate marca ca citit
- Istoricul mesajelor e protejat

#### Notificări
- Fiecare utilizator vede doar propriile notificări
- Server-ul poate crea notificări pentru oricine
- Notificările pending sunt private pentru server

#### Marketplace
- Anunțurile sunt publice pentru citire
- Doar proprietarul poate modifica anunțul
- Prețurile sunt monitorizate de sistem

#### Favorite
- Favorite personale sunt private
- Favorite globale pentru notificări sunt vizibile
- Sistemul poate crea statistici

## 🚀 Cum să Aplici Regulile

1. **Deschide Firebase Console**
2. **Mergi la Firestore Database**
3. **Click pe Rules**
4. **Înlocuiește regulile existente cu cele de mai sus**
5. **Click Publish**

## ⚠️ Importante de Reținut

- **Testează regulile** înainte de a le publica în producție
- **Folosește Firebase Emulator** pentru testare locală
- **Monitor logs** pentru erori de permisiuni
- **Service Account** pentru server are permisiuni admin complete
- **Backup regulile** înainte de modificări majore

Aceste reguli asigură că sistemul de notificări și mesagerie funcționează în siguranță! 🔒
