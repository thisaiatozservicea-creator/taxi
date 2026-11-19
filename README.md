# TSY TAXI Booking System

Full-stack taxi booking application with MongoDB database.

## Features

- **Firebase Authentication**: Email/Phone/Google sign-in
- **Automatic Login**: User logged in once stays logged in
- **Firestore Database**: All data stored in Firebase Firestore (users, bookings, profiles)
- **Auto-fill Profile**: Customer data automatically loaded from Firestore and filled in booking
- Real-time fare calculation (₹20/km)
- OpenStreetMap integration with Leaflet
- 50km service radius around Thisayanvilai
- Customer profile management (synced with Firestore)

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Firestore Security Rules

**IMPORTANT:** Admin dashboard requires proper Firestore permissions.

Go to Firebase Console and update Firestore rules:
```
https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/rules
```

Copy rules from `firestore.rules` file or see `FIRESTORE_SETUP.md` for detailed instructions.

**Quick fix for testing:**
```
match /bookings/{bookingId} {
  allow read, write: if request.auth != null;
}
```

### 3. Environment Variables

Already configured in `.env`:
- Port: 3000
- All data stored in Firebase Firestore (no MongoDB needed)

### 4. Start Server

```bash
npm start
```

Or for development with auto-reload:

```bash
npm run dev
```

### 5. Access Application

**Option 1:** Via Node.js server
```
http://localhost:3000
```

**Option 2:** Via VS Code Live Server or directly open `login.html` in browser

All data stored in Firestore, so any web server works.

## Data Storage

All data saved directly to Firebase Firestore from frontend. No API calls needed for data storage.

- User profiles saved to Firestore `users` collection
- Bookings saved to Firestore `bookings` collection
- Backend only serves static HTML files

## Firestore Collections

### users collection
Stores user profiles for authentication and profile management.

```json
{
  "uid": "firebase_user_id",
  "name": "string",
  "phone": "string",
  "email": "string",
  "address": "string",
  "lastLogin": "ISO date string",
  "createdAt": "ISO date string",
  "updatedAt": "ISO date string"
}
```

### bookings collection
Stores all bookings and trip history.
```json
{
  "bookingId": "string (TSY + timestamp)",
  "passenger": {
    "name": "string",
    "phone": "string",
    "email": "string"
  },
  "pickup": {
    "lat": "number",
    "lon": "number",
    "displayName": "string",
    "area": "string"
  },
  "destination": {
    "lat": "number",
    "lon": "number",
    "displayName": "string",
    "area": "string"
  },
  "distanceMeters": "number",
  "distanceKm": "number",
  "fare": "number",
  "ratePerKm": "number",
  "estimatedDurationSeconds": "number",
  "estimatedDuration": "string",
  "bookingTime": "Date",
  "status": "string",
  "createdAt": "Date"
}
```

## Tech Stack

- **Frontend**: HTML5, CSS3, JavaScript (ES6+ Modules)
- **Backend**: Node.js, Express (minimal API server)
- **Authentication**: Firebase Authentication
- **Database**: Firebase Firestore (users, profiles, bookings)
- **Maps**: OpenStreetMap + Leaflet.js
- **Geocoding**: Nominatim API

## File Structure

```
tsytaxi/
├── login.html         # Firebase authentication login page
├── home.html          # Main booking page
├── booking.html       # Booking confirmation page
├── admin.html         # Admin dashboard for managing bookings
├── server.js          # Express backend
├── package.json       # Dependencies
├── .env              # Environment variables
├── .gitignore        # Git ignore file
├── logo.jpeg         # TSY TAXI logo
├── auto.jpeg         # Auto rickshaw image
└── README.md         # Documentation
```

## User Flow

1. **First Visit**: User logs in via Firebase (email/phone/Google) → User data saved to Firestore + localStorage
2. **Return Visit**: User automatically redirected to home page (skips login page)
3. **Home Page**: User profile loaded from Firestore
4. **Booking**: Customer data (name, phone, email) auto-filled from Firestore profile
5. **Booking Confirmation**: After submit, shows countdown (2→0) with "Waiting for auto confirmation"
6. **Admin Confirmation**: Admin reviews booking on admin dashboard and confirms/rejects
7. **Customer Notified**: Customer sees real-time confirmation on booking page
8. **Profile Edit**: Changes saved to both Firestore and localStorage
9. **Logout**: Clears localStorage and redirects to login page

## Admin Dashboard

Access admin panel at: `http://localhost:3000/admin.html`

Features:
- Real-time booking list with status updates
- Statistics (Pending, Confirmed, Total bookings)
- Confirm or Reject bookings
- Auto-refresh when new bookings arrive

## Mobile Responsive

Fully optimized for mobile devices with touch-friendly UI.

## Support

For issues or questions, contact TSY TAXI support.
