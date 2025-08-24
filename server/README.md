# LuWay Notification Server

Server Node.js pentru gestionarea notificărilor FCM ale aplicației LuWay.

## 🚀 Setup

### 1. Instalare dependințe
```bash
cd server
npm install
```

### 2. Configurare Firebase Service Account

1. Mergi în Firebase Console → Project Settings → Service Accounts
2. Generează o nouă cheie privată pentru service account-ul `fcm-server@bipcar-7464a.iam.gserviceaccount.com`
3. Descarcă fișierul JSON și redenumește-l în `service-account-key.json`
4. Plasează fișierul în directorul `server/`

### 3. Configurare environment
Copiază fișierul `.env` și actualizează variabilele dacă este necesar.

### 4. Pornire server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

## 📱 Funcționalități

### Notificări automate:
- ✅ **Mesaje noi** - când cineva trimite un mesaj
- ✅ **Anunțuri favorite** - când cineva adaugă anunțul la favorite  
- ✅ **Modificări preț** - când se schimbă prețul unui anunț favorit
- ✅ **Rezumat zilnic** - câte persoane au adăugat anunțurile la favorite

### Programare automată:
- 🔔 Verifică notificări în așteptare: **la fiecare 30 secunde**
- 📊 Trimite rezumatul zilnic: **în fiecare zi la 20:00**
- 🧹 Curăță notificările vechi: **zilnic la 02:00**

## 🛠️ API Endpoints

### GET /health
Verifică starea serverului
```bash
curl http://localhost:3000/health
```

### POST /send-pending
Forțează trimiterea notificărilor în așteptare
```bash
curl -X POST http://localhost:3000/send-pending
```

### POST /send-daily-summary  
Forțează trimiterea rezumatului zilnic
```bash
curl -X POST http://localhost:3000/send-daily-summary
```

### POST /test-notification
Trimite o notificare de test
```bash
curl -X POST http://localhost:3000/test-notification \
  -H "Content-Type: application/json" \
  -d '{
    "token": "FCM_TOKEN_HERE",
    "title": "Test Notification",
    "body": "This is a test message"
  }'
```

## 🔧 Configurare

### Variabile environment (.env):
- `FIREBASE_PROJECT_ID` - ID-ul proiectului Firebase
- `PORT` - Portul pe care rulează serverul (default: 3000)
- `MAX_NOTIFICATIONS_PER_BATCH` - Numărul maxim de notificări per batch (default: 100)
- `DAILY_SUMMARY_HOUR` - Ora la care se trimite rezumatul zilnic (default: 20)

### Service Account Permissions:
Service account-ul trebuie să aibă următoarele permisiuni:
- `Firebase Admin SDK Administrator Service Agent`
- `Cloud Messaging Admin`

## 📊 Monitoring

Serverul loghează toate operațiunile:
- ✅ Notificări trimise cu succes
- ❌ Erori de trimitere  
- 📊 Statistici batch-uri
- 🧹 Operațiuni de curățare

## 🚀 Deployment

### Pentru producție:
1. Folosește un process manager ca PM2:
```bash
npm install -g pm2
pm2 start server.js --name "luway-notifications"
```

2. Sau folosește Docker:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Variabile de mediu pentru producție:
```bash
NODE_ENV=production
PORT=3000
FIREBASE_PROJECT_ID=bipcar-7464a
```

## 🔒 Securitate

- ⚠️ **Nu commitați niciodată** `service-account-key.json` în Git
- 🔐 Păstrați cheia service account securizată
- 🌐 Folosiți HTTPS în producție
- 🔥 Configurați firewall pentru a restricționa accesul la server
