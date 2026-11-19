# Firestore Security Rules - TSY TAXI

## Firebase Projects

This project uses **TWO** Firebase projects:

1. **tsytaxi-7e9b0** - Partner & Customer Management
   - Partners collection
   - Customers collection  
   - Partner Requests collection
   - Used by: `superadmin.html`, `partner-login.html`

2. **tsytaxi-fcbd3** - Booking Management
   - Bookings collection (active trips only, auto-deleted when completed)
   - Users collection (customer profiles)
   - Trips collection (completed trip history for partner revenue tracking)
   - Used by: `admin.html`, `partner-dashboard.html`, main booking app

---

## Firestore Rules for `tsytaxi-7e9b0`

Go to: https://console.firebase.google.com/project/tsytaxi-7e9b0/firestore/rules

Copy and paste these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Partners collection - Full access for login, profile updates, online status
    match /partners/{partnerId} {
      allow read: if true;
      allow write: if true; // Partners need to update profile, online status, location
    }
    
    // Customers collection
    match /customers/{customerId} {
      allow read: if true;
      allow write: if true; // Allow customer registration and updates
    }
    
    // Partner Requests collection
    match /partnerRequests/{requestId} {
      allow read: if true;
      allow create: if true; // Allow new partner applications
      allow update: if true; // Allow superadmin to approve/reject
      allow delete: if true; // Allow superadmin to delete rejected requests
    }
    
    // Users collection (for customer data from Firebase Auth)
    match /users/{userId} {
      allow read: if true;
      allow write: if true;
    }
    
    // Deny all other collections by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Click "Publish" to save the rules.**

---

## Firestore Rules for `tsytaxi-fcbd3`

Go to: https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/rules

Copy and paste these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Bookings collection - Full public access
    match /bookings/{bookingId} {
      allow read: if true;
      allow create: if true; // Allow customers to create bookings
      allow update: if true; // Allow admin/partner to update status
      allow delete: if true; // Allow admin to delete bookings
    }
    
    // Users collection - Full public access
    match /users/{userId} {
      allow read: if true;
      allow write: if true; // Allow user data storage from Firebase Auth
    }
    
    // Trips collection - Completed trip history
    match /trips/{tripId} {
      allow read: if true;
      allow create: if true; // Partners save completed trips
      allow update: if false; // Trips are immutable once saved
      allow delete: if false; // Never delete trip history
    }
    
    // Deny all other collections by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Click "Publish" to save the rules.**

---

## Data Structures in Firestore

### Partner Fields (tsytaxi-7e9b0/partners)

When a partner is created and logs in, the following fields are stored:

- `partnerId` - Unique partner ID (set by superadmin)
- `name` - Partner full name (set during first login)
- `password` - Partner password (plain text - **hash in production!**)
- `phone` - Partner phone number (set during first login)
- `email` - Partner email address (optional, set during first login)
- `vehicleNumber` - Vehicle registration number (set during first login)
- `active` - Account active status (boolean)
- `deactivatedAt` - Timestamp when account was blocked (if blocked)
- `isOnline` - Whether partner is currently online and accepting bookings
- `onlineAt` - Timestamp when partner went online
- `onlineStartTime` - Unix timestamp for calculating online duration
- `offlineAt` - Timestamp when partner went offline
- `currentLocation` - GPS location object with latitude, longitude, accuracy, and timestamp (updated when partner goes online)
- `createdAt` - Account creation timestamp
- `detailsCompletedAt` - When partner completed profile
- `profileUpdatedAt` - When partner last edited their profile

### Customer/User Fields (tsytaxi-fcbd3/users)

When a customer books a ride, their profile is saved/updated:

- `userId` - Unique user ID (Firebase Auth UID or guest_timestamp)
- `name` - Customer full name
- `phone` - Customer phone number
- `email` - Customer email address
- `lastBookingAt` - Timestamp of most recent booking
- `updatedAt` - When profile was last updated

### Booking Fields (tsytaxi-fcbd3/bookings)

When a booking is created:

- `bookingId` - Unique booking ID (TSY + timestamp)
- `userId` - Customer user ID
- `status` - Booking status (PENDING, ASSIGNED, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED)
- `pickup` - Pickup location object (lat, lon, area, displayName)
- `destination` - Destination location object (lat, lon, area, displayName)
- `distanceKm` - Trip distance in kilometers
- `fare` - Total fare amount
- `passenger` - Passenger details object (name, phone, email)
- `partnerId` - Assigned partner ID (when assigned)
- `partnerName` - Assigned partner name (when assigned)
- `partnerPhone` - Assigned partner phone (when assigned)
- `partnerVehicle` - Assigned partner vehicle (when assigned)
- `createdAt` - Booking creation timestamp
- `assignedAt` - When partner was assigned (if assigned)
- `acceptedAt` - When partner accepted trip (if accepted)
- `arrivedAt` - When partner marked arrival (if arrived)
- `completedAt` - When trip was completed (if completed)
- `cancelledAt` - When booking was cancelled (if cancelled)

## Testing Rules

### Test Partner Login
1. Open `superadmin.html`
2. Login: username=`muthu`, password=`muthu`
3. Create a test partner:
   - Name: Leave blank (will be filled during login)
   - Partner ID: `TSY001`
   - Password: `test123`
4. Open `partner-login.html`
5. Login with Partner ID=`TSY001`, Password=`test123`
6. Fill in:
   - Name: `Test Driver`
   - Phone: `9876543210`
   - Email: `test@example.com` (optional)
   - Vehicle: `TN01AB1234`
7. Dashboard loads with:
   - Login hours counter (⏱ 0h 0m) in top navbar
   - Profile button (👤) opens sidebar
8. Click "Start Booking" to go online
9. Open `admin.html` to see online partner with all details
10. Click Profile button → Edit → change details → Save
11. Open `superadmin.html` → Partners tab → see updated details

### Test Booking Flow
1. Open main booking page (customer side)
2. Create a booking
3. Open `admin.html`
4. Confirm the booking

---

## Important Notes

⚠️ **Security Warning**: Current setup stores passwords in **plain text** in Firestore. This is for development only.

**For production:**
- Hash passwords using bcrypt or similar
- Use Firebase Authentication for partners
- Add proper role-based access control
- Enable App Check for API protection

---

## Troubleshooting

**Error: "Missing or insufficient permissions"**
- Check that you published the rules in the correct Firebase project
- Wait 10-30 seconds after publishing rules
- Clear browser cache and reload page

**Error: "Partner ID not found"**
- Verify partner was created via superadmin panel
- Check Firebase Console → Firestore → `partners` collection
- Ensure Partner ID matches exactly (case-sensitive)

**Bookings not showing in admin.html**
- Verify you're using the `tsytaxi-fcbd3` project
- Check rules are published in correct project
- Inspect browser console for errors
