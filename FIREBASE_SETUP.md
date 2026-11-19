# Firebase Setup Guide for TSY TAXI

## Step 1: Create Firebase Project

1. Go to **https://console.firebase.google.com**
2. Click "Add project"
3. Enter project name: **TSY-TAXI**
4. Disable Google Analytics (optional)
5. Click "Create project"

## Step 2: Get Configuration

1. In Firebase Console, click gear icon ⚙️ → Project settings
2. Scroll down to "Your apps"
3. Click **Web** icon (</>) to add web app
4. App nickname: **TSY TAXI Web**
5. Click "Register app"
6. Copy the `firebaseConfig` object

Example config:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",
  authDomain: "tsy-taxi.firebaseapp.com",
  projectId: "tsy-taxi",
  storageBucket: "tsy-taxi.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123"
};
```

## Step 3: Enable Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Select **Start in production mode**
4. Choose location: **asia-south1 (Mumbai)** (closest to India)
5. Click "Enable"

## Step 4: Set Security Rules

1. In Firestore, go to **Rules** tab
2. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - stores name, phone, address only
    match /users/{phone} {
      allow read: if true;
      allow write: if true;
    }
  }
}
```

3. Click **Publish**

## Step 5: Update Your App

Replace Firebase config in BOTH files:

### home.html (line 229):
```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY_HERE",  // ← Replace this
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

### booking.html (around line 165):
Same config - copy/paste from home.html

## Step 6: Test

1. Open home.html in browser
2. Check browser console (F12) - should see "✓ Firebase connected"
3. Complete a booking
4. Go to Firebase Console → Firestore Database
5. You should see:
   - `bookings` collection with your booking
   - `users` collection with your profile

## Database Structure

### users/{phone}
```json
{
  "name": "John Doe",
  "phone": "9876543210",
  "address": "123 Main St, Village, District",
  "lastUpdated": "2024-01-15T10:30:00.000Z"
}
```

**Note:** Only user profile data (name, phone, address) is stored in Firebase. Booking history is stored locally in browser localStorage.

## Features Enabled

✓ **Permanent storage** - Data never lost (even if browser cache cleared)
✓ **Cross-device sync** - Login from any device with phone number
✓ **Booking history** - All bookings stored forever
✓ **User profiles** - Name, phone, address saved
✓ **Real-time** - Changes sync instantly
✓ **Free tier** - 1GB storage, 50K reads/day, 20K writes/day

## Cost (Free Tier Limits)

- **Reads**: 50,000/day (enough for 100+ users/day)
- **Writes**: 20,000/day (enough for 500 bookings/day)
- **Storage**: 1GB (enough for 100,000+ bookings)

**You won't pay anything with your usage (100 bookings/day).**

## Troubleshooting

**"Firebase not configured"** in console:
- Replace YOUR_API_KEY_HERE with real API key

**"Permission denied"** error:
- Check Firestore Rules (Step 4)
- Publish rules

**Data not saving**:
- Open browser console (F12)
- Check for errors
- Verify Firebase config is correct

## Without Firebase

If you don't add Firebase config, app works with **localStorage fallback**:
- Data saved locally in browser
- Lost if cache cleared
- No cross-device sync
- Still works perfectly for single device

**Firebase is optional but recommended for production.**
