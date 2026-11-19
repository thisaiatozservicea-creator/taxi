# Firestore Rules Deployment Guide

TSY TAXI uses **two separate Firebase projects** with different Firestore databases:

## 1. Bookings Database (tsytaxi-fcbd3)
**Purpose:** Real-time booking data, trip history, and customer information

**Rules File:** `firestore.rules`

**Collections:**
- `bookings` - Active bookings in real-time
- `trips` - Completed trip history
- `users` - Customer accounts

**Deploy Command:**
```bash
firebase deploy --only firestore:rules --project tsytaxi-fcbd3
```

---

## 2. Partners Database (tsytaxi-7e9b0)
**Purpose:** Partner accounts, partner requests, and partner management

**Rules File:** `firestore-partners.rules`

**Collections:**
- `partners` - Partner accounts with login credentials
- `partnerRequests` - New partner application requests

**Deploy Command:**
```bash
firebase deploy --only firestore:rules --project tsytaxi-7e9b0
```

---

## Complete Deployment Steps

### Step 1: Install Firebase CLI (if not already installed)
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Deploy Bookings Database Rules
```bash
# Navigate to project directory
cd "C:\Users\MUTHU KRISHNAN\OneDrive\New project\tsytaxi"

# Deploy to bookings database
firebase deploy --only firestore:rules --project tsytaxi-fcbd3
```

### Step 4: Deploy Partners Database Rules
```bash
# Copy partners rules to firebase.json location
# Then deploy to partners database
firebase deploy --only firestore:rules --project tsytaxi-7e9b0
```

---

## Manual Deployment (Firebase Console)

If you prefer to deploy via Firebase Console:

### For Bookings Database (tsytaxi-fcbd3):
1. Go to https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/rules
2. Copy contents of `firestore.rules`
3. Paste into the rules editor
4. Click "Publish"

### For Partners Database (tsytaxi-7e9b0):
1. Go to https://console.firebase.google.com/project/tsytaxi-7e9b0/firestore/rules
2. Copy contents of `firestore-partners.rules`
3. Paste into the rules editor
4. Click "Publish"

---

## Security Notes

⚠️ **IMPORTANT:** Current rules use `allow read/write: if true` for development convenience.

**For PRODUCTION**, you MUST:
1. Implement Firebase Authentication
2. Add proper role-based access control
3. Validate request data with schema rules
4. Add rate limiting
5. Remove public write access

Example production rule:
```javascript
match /partners/{partnerId} {
  // Only allow partners to read/write their own data
  allow read: if request.auth != null && request.auth.uid == partnerId;
  allow write: if request.auth != null && request.auth.uid == partnerId;
}

// Only admins can update partner status
match /partners/{partnerId} {
  allow update: if request.auth != null && 
                   request.auth.token.admin == true;
}
```

---

## Testing Rules

Test rules using Firebase Emulator:
```bash
firebase emulators:start --only firestore
```

Then run your app against the emulator by updating Firebase config:
```javascript
const db = getFirestore(app);
connectFirestoreEmulator(db, 'localhost', 8080);
```

---

## Real-time Data Flow

```
Customer App (home.html, booking.html, booking-status.html)
  ↓
Bookings Database (tsytaxi-fcbd3)
  ├─ bookings collection (real-time booking status)
  ├─ trips collection (completed trip history)
  └─ users collection (customer profiles)
  
Partner App (partner-dashboard.html)
  ↓
Partners Database (tsytaxi-7e9b0) + Bookings Database
  ├─ partners collection (partner accounts)
  ├─ bookings collection (read/write active trips)
  └─ trips collection (read completed trip history)
  
Super Admin (superadmin.html)
  ↓
Both Databases
  ├─ Read all partners
  ├─ Read all bookings
  ├─ Read all customers
  └─ Manage partner accounts
```
