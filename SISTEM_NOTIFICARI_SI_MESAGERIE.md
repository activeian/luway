# 📱 Sistemul de Notificări și Mesagerie - LuWAy

## 🎯 Ce Am Implementat

Am creat un sistem complet de notificări și mesagerie pentru aplicația LuWAy care te anunță când se întâmplă lucruri importante și îți permite să comunici cu alți utilizatori.

## 📞 Cum Funcționează Mesageria

### Trimiterea Mesajelor
- Când trimiți un mesaj cuiva, se salvează în Firebase Firestore
- Mesajul ajunge instant la destinatar prin Firebase Streams
- Se creează automat o conversație între voi doi
- Fiecare mesaj are: expeditor, destinatar, conținut, timp și stare (citit/necitit)

### Chat List (Lista de Conversații)
- Vezi toate conversațiile tale într-o listă
- Pentru fiecare conversație vezi:
  - Numele/marca mașinii
  - Ultimul mesaj trimis
  - Când a fost trimis
  - **BONUS: Badge roșu cu numărul de mesaje necitite**

### Mesaje Necitite
- Când primești mesaje noi, se afișează badge-uri roșii cu numere
- În chat list: fiecare conversație arată câte mesaje necitite are
- În bottom navigation: tab-ul "Chat" arată totalul de mesaje necitite
- Badge-urile dispar automat când citești mesajele

## 🔔 Sistemul de Notificări

### Tipuri de Notificări

#### 1. **Notificări de Mesaje** 💬
- **Când se activează**: Cineva îți trimite un mesaj
- **Ce primești**: Notificare push + notificare în app
- **Ce vezi**: "Nume utilizator ți-a trimis un mesaj: [preview mesaj]"
- **La tap**: Te duce direct în conversația respectivă

#### 2. **Notificări de Favorite** ❤️
- **Când se activează**: Cineva adaugă anunțul tău la favorite
- **Ce primești**: Notificare push + notificare în app
- **Ce vezi**: "Anunțul tău [marca mașină] a fost adăugat la favorite"
- **La tap**: Te duce la anunțul respectiv

#### 3. **Notificări de Preț** 💰
- **Când se activează**: Se schimbă prețul unei mașini pe care o ai la favorite
- **Ce primești**: Notificare push + notificare în app
- **Ce vezi**: "Prețul pentru [marca mașină] s-a schimbat: [preț vechi] → [preț nou]"
- **La tap**: Te duce la anunțul cu prețul actualizat

#### 4. **Notificări Sumar Zilnic** 📊
- **Când se activează**: În fiecare seară la 20:00
- **Ce primești**: Rezumatul zilei cu statistici
- **Ce vezi**: "Astăzi: X persoane au adăugat anunțurile tale la favorite"
- **La tap**: Te duce la statistici (dacă există)

### Cum Ajung Notificările la Tine

#### Client-Side (În Aplicație)
1. **Firebase Cloud Messaging (FCM)** - sistemul de notificări push
2. **NotificationService** - gestionează toate notificările în app
3. **Flutter Local Notifications** - afișează notificările chiar dacă aplicația e închisă

#### Server-Side (În Spate)
- **Server Node.js** care rulează continuu
- Verifică la fiecare 30 de secunde dacă sunt notificări de trimis
- La 20:00 în fiecare zi trimite sumarele zilnice
- Folosește Firebase Admin SDK pentru a trimite notificări

## 🎨 Interfața Utilizator

### Ecranul de Notificări
- Lista cu toate notificările primite
- Culori diferite pentru fiecare tip de notificare:
  - 🔵 Albastru = Mesaje
  - 🔴 Roșu = Favorite
  - 🟠 Portocaliu = Schimbări preț
  - 🫒 Verde oliv = Sumar zilnic
- Notificările necitite au fundal colorat
- Poți șterge toate notificările dintr-o dată

### Badge-uri și Indicatori
- **În Home**: Butonul de notificări are badge cu numărul de notificări necitite
- **În Chat**: Tab-ul de chat are badge cu mesajele necitite totale
- **În Chat List**: Fiecare conversație are badge cu mesajele necitite din acea conversație

## 🔄 Fluxul Complet

### Exemplu: Trimitem un Mesaj
1. **Tu** scrii un mesaj și apeși "Trimite"
2. **ChatService** salvează mesajul în Firebase
3. **NotificationService** trimite notificare destinatarului
4. **Destinatarul** primește notificare push pe telefon
5. **Server-ul** procesează și trimite notificarea prin FCM
6. **Badge-urile** se actualizează automat în timp real

### Exemplu: Adaugi o Mașină la Favorite
1. **Tu** apeși pe inimioară la o mașină
2. **FavoritesService** salvează în Firebase și trimite notificare
3. **Proprietarul** primește notificare că îi place mașina cuiva
4. **PriceMonitoringService** începe să monitorizeze prețul acelei mașini
5. Dacă se schimbă prețul, **tu** primești notificare

## 📱 Funcționalități Smart

### Actualizare în Timp Real
- Toate badge-urile se actualizează instant folosind Firebase Streams
- Nu trebuie să restarți aplicația să vezi schimbările
- Funcționează pe multiple device-uri simultan

### Managementul Mesajelor Citite
- Când deschizi o conversație, mesajele se marchează automat ca citite
- Badge-urile dispar instant pentru UX mai bun
- Funcționează și când vii din notificări

### Monitorizarea Prețurilor
- Sistemul verifică automat schimbările de preț
- Ține istoric cu toate schimbările
- Trimite notificări doar pentru schimbări semnificative

## 🛠️ Tehnologii Folosite

### Frontend (Flutter)
- **Firebase Cloud Messaging** - notificări push
- **Flutter Local Notifications** - notificări locale
- **Firebase Firestore** - baza de date în timp real
- **Flutter Streams** - actualizări live

### Backend (Node.js Server)
- **Express.js** - server web
- **Firebase Admin SDK** - trimitere notificări
- **Node-cron** - task-uri programate
- **Firestore** - stocarea datelor

### Infrastructura
- **Firebase Console** - configurare FCM
- **Firestore Database** - colecții: users, conversations, notifications, favorites
- **Firebase Security Rules** - protecția datelor (vezi FIREBASE_SECURITY_RULES.md)
- **Firebase Functions** - procesare automată (opțional)

## 🔐 Configurare Securitate

Pentru ca sistemul să funcționeze corect și în siguranță, trebuie să configurezi:

1. **Firebase Security Rules** - vezi fișierul `FIREBASE_SECURITY_RULES.md` pentru reguli complete
2. **Service Account** pentru server - permite serverului să trimită notificări
3. **FCM Setup** - activează Cloud Messaging în Firebase Console
4. **Firestore Collections** - structura bazei de date

**IMPORTANT**: Regulile de securitate sunt esențiale pentru a proteja datele utilizatorilor și pentru ca sistemul de notificări să funcționeze corect!

## 🎉 Rezultatul Final

Acum ai:
- ✅ Notificări push pentru toate evenimentele importante
- ✅ Chat cu badge-uri pentru mesaje necitite
- ✅ Monitorizare automată a prețurilor
- ✅ Sumare zilnice cu statistici
- ✅ Interfață intuitivă și responsive
- ✅ Sincronizare în timp real pe toate device-urile

Sistemul e complet automatizat și oferă o experiență fluidă pentru utilizatori! 🚀
