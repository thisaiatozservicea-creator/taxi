# TSY TAXI - Complete Data Flow Documentation

## Firebase Projects

### Project 1: tsytaxi-7e9b0 (Partners & Admin Management)
**Collections:**
- `partners` - Partner accounts
- `customers` - (Legacy, not used)
- `partnerRequests` - Partner registration requests

### Project 2: tsytaxi-fcbd3 (Bookings & Customer Data)
**Collections:**
- `bookings` - All ride bookings
- `users` - Customer profiles

---

## Complete Booking Flow with Data Storage

### 1. Customer Books Ride

**Page:** `home.html` → `booking.html`

**Actions:**
1. Customer selects pickup and destination
2. System calculates fare
3. Customer fills: Name, Phone, Email
4. Clicks "CONFIRM BOOKING"

**Data Saved to Firestore (tsytaxi-fcbd3):**

```javascript
// Collection: users/{userId}
{
  userId: "guest_1732025308331",
  name: "John Doe",
  phone: "9876543210",
  email: "john@example.com",
  lastBookingAt: "2026-11-19T10:30:00.000Z",
  updatedAt: "2026-11-19T10:30:00.000Z"
}

// Collection: bookings/{docId}
{
  bookingId: "TSY1732025308331",
  userId: "guest_1732025308331",
  status: "PENDING",
  pickup: {
    lat: 8.336111,
    lon: 77.864444,
    area: "Thisayanvilai",
    displayName: "Thisayanvilai, Tamil Nadu"
  },
  destination: {
    lat: 8.345678,
    lon: 77.875432,
    area: "Idayankudi",
    displayName: "Idayankudi, Tamil Nadu"
  },
  distanceKm: 3.45,
  fare: 69.06,
  passenger: {
    name: "John Doe",
    phone: "9876543210",
    email: "john@example.com"
  },
  createdAt: "2026-11-19T10:30:00.000Z"
}
```

**Customer Redirected To:** `booking-status.html?id={docId}`

---

### 2. Admin Assigns Partner

**Page:** `admin.html`

**Admin Sees:**
- Online Partners section (shows partners with `isOnline: true`)
- Recent Bookings section (shows PENDING bookings)
- Auto-timeout: PENDING bookings older than 5 minutes are deleted

**Actions:**
1. Admin clicks "ASSIGN PARTNER" on PENDING booking
2. Modal shows online partners sorted by:
   - Distance to pickup (nearest first)
   - Login time (earliest first)
3. Admin selects partner

**Data Updated in Firestore (tsytaxi-fcbd3):**

```javascript
// bookings/{docId} - Updated fields
{
  status: "ASSIGNED",
  partnerId: "TSY001",
  partnerName: "Muthu",
  partnerPhone: "8459075088",
  partnerVehicle: "TN31AZ1234",
  assignedAt: "2026-11-19T10:31:00.000Z"
}
```

---

### 3. Partner Accepts Trip

**Page:** `partner-dashboard.html`

**Partner Sees:**
- Orange pulsing notification card with trip details
- Accept / Decline buttons

**Actions:**
1. Partner clicks "ACCEPT"

**Data Updated in Firestore (tsytaxi-fcbd3):**

```javascript
// bookings/{docId} - Updated fields
{
  status: "ACCEPTED",
  acceptedAt: "2026-11-19T10:32:00.000Z"
}
```

**Customer Sees (booking-status.html):**
- "Partner Assigned" screen with driver details
- Call button

---

### 4. Partner Arrives at Pickup

**Page:** `partner-dashboard.html`

**Actions:**
1. Partner clicks "I HAVE ARRIVED"

**Data Updated in Firestore (tsytaxi-fcbd3):**

```javascript
// bookings/{docId} - Updated fields
{
  status: "IN_PROGRESS",
  arrivedAt: "2026-11-19T10:35:00.000Z"
}
```

**Customer Sees (booking-status.html):**
- **Popup Notification:** "🎉 Driver Arrived!" (5 seconds)
- Map view with "Trip in progress to destination"

---

### 5. Partner Completes Trip

**Page:** `partner-dashboard.html`

**Actions:**
1. Partner clicks "END TRIP"
2. Confirmation shown
3. Partner stays ONLINE for next booking

**Data Updated in Firestore (tsytaxi-fcbd3):**

```javascript
// bookings/{docId} - Updated fields
{
  status: "COMPLETED",
  completedAt: "2026-11-19T10:45:00.000Z"
}
```

**Auto-Delete:**
- Booking is automatically deleted from Firestore
- Stored in partner's trip history (read before delete)

**Customer Sees (booking-status.html):**
- "🎉 Trip Completed!" screen
- Trip summary with fare and distance

**Partner Dashboard Updates:**
- Total Revenue: +₹69.06
- Today Revenue: +₹69.06
- Completed Trips: +1

---

## Partner Data Flow

### Partner Creation

**Page:** `superadmin.html`

**Actions:**
1. Superadmin creates partner account
2. Provides: Name, Partner ID, Password

**Data Saved to Firestore (tsytaxi-7e9b0):**

```javascript
// partners/{partnerId}
{
  partnerId: "TSY001",
  name: "",
  password: "test123",
  active: true,
  createdAt: "2026-11-19T09:00:00.000Z"
}
```

---

### Partner First Login

**Page:** `partner-login.html` → `partner-dashboard.html`

**Actions:**
1. Partner enters Partner ID + Password
2. Session saved to localStorage
3. Completes profile (Name, Phone, Email, Vehicle)

**Data Updated in Firestore (tsytaxi-7e9b0):**

```javascript
// partners/{partnerId}
{
  partnerId: "TSY001",
  name: "Muthu",
  password: "test123",
  phone: "8459075088",
  email: "muthu@example.com",
  vehicleNumber: "TN31AZ1234",
  active: true,
  detailsCompletedAt: "2026-11-19T09:05:00.000Z",
  createdAt: "2026-11-19T09:00:00.000Z"
}
```

**Session Storage:**
```javascript
// localStorage.tsyPartnerSession
{
  partnerId: "TSY001",
  id: "firestore-doc-id"
}
```

---

### Partner Goes Online

**Page:** `partner-dashboard.html`

**Actions:**
1. Partner clicks "Start Booking"
2. GPS location captured
3. Address shown via reverse geocoding

**Data Updated in Firestore (tsytaxi-7e9b0):**

```javascript
// partners/{partnerId}
{
  isOnline: true,
  onlineAt: "2026-11-19T10:00:00.000Z",
  onlineStartTime: 1732025400000,
  currentLocation: {
    latitude: 8.336111,
    longitude: 77.864444,
    accuracy: 15,
    timestamp: 1732025400000
  }
}
```

---

### Partner Goes Offline

**Actions:**
1. Partner clicks "Stop Booking"

**Data Updated in Firestore (tsytaxi-7e9b0):**

```javascript
// partners/{partnerId}
{
  isOnline: false,
  offlineAt: "2026-11-19T16:00:00.000Z"
}
```

---

### Partner Logout

**Actions:**
1. Partner clicks "Logout"
2. If online, status changed to offline
3. Session cleared

**Data Cleared:**
- `localStorage.tsyPartnerSession` removed

**Redirect:** `partner-login.html`

---

## Account Management

### Partner Account Deactivation

**Page:** `superadmin.html`

**Actions:**
1. Superadmin clicks "Deactivate" on partner

**Data Updated in Firestore (tsytaxi-7e9b0):**

```javascript
// partners/{partnerId}
{
  active: false,
  deactivatedAt: "2026-11-19T14:00:00.000Z"
}
```

**Partner Side:**
- Auto-login check fails
- Redirected to blocked screen
- Cannot access dashboard

---

### Partner Account Reactivation

**Actions:**
1. Superadmin clicks "Activate" on partner

**Data Updated in Firestore (tsytaxi-7e9b0):**

```javascript
// partners/{partnerId}
{
  active: true,
  deactivatedAt: null
}
```

**Partner Side:**
- Can login normally
- Session works again

---

## Revenue Tracking

### Partner Revenue Data

**Source:** `tsytaxi-fcbd3/bookings` collection (Real-time listener)

**Query:**
```javascript
where("partnerId", "==", "TSY001")
// Real-time onSnapshot listener
```

**Calculations (Auto-updates):**
- **Total Revenue:** Sum of all completed trip fares
- **Today Revenue:** Sum of today's completed trip fares
- **Trip Count:** Count of completed trips (COMPLETED + CANCELLED)
- **Total Distance:** Sum of distanceKm from all trips
- **Total Hours:** Sum of (completedAt - acceptedAt) for all trips

**Display Locations (All Real-time):**
- Partner Dashboard sidebar (👤 Profile menu)
- Partner Dashboard revenue screens
- Superadmin partner "Full View" modal

---

### Customer Spending Data

**Source:** `tsytaxi-fcbd3/bookings` collection

**Query:**
```javascript
where("userId", "==", "customer-uid")
where("status", "==", "COMPLETED")
```

**Calculations:**
- **Total Spent:** Sum of all completed trip fares
- **Trip Count:** Count of completed trips

**Display Location:**
- Superadmin customers section

---

## Auto-Deletion Rules

### Bookings Auto-Delete When:

1. **Status = COMPLETED**
   - Deleted immediately after partner clicks "END TRIP"
   - Revenue already calculated and stored

2. **Status = CANCELLED**
   - Deleted immediately after cancellation

3. **Status = PENDING for > 5 minutes**
   - Auto-timeout if admin doesn't assign
   - Customer sees "Cancelled" screen

**Why Auto-Delete:**
- Keeps admin dashboard clean
- Only shows active bookings
- Completed trips stored in revenue calculations before deletion

---

## Real-Time Updates (onSnapshot)

### Customer Side (booking-status.html)
**Listens to:** `bookings/{docId}`
**Updates on:** Status changes (PENDING → ASSIGNED → ACCEPTED → IN_PROGRESS → COMPLETED)

### Partner Side (partner-dashboard.html)
**Listens to:** 
- `partners/{partnerId}` (tsytaxi-7e9b0) - Profile updates
- `bookings` where `partnerId == current` (tsytaxi-fcbd3) - Trip/stats updates

**Updates on:** 
- Profile changes (name, phone, email, vehicle, account status)
- New trip assignments, status changes
- **Real-time revenue/stats updates** (total revenue, today revenue, completed trips)
- Account blocking (auto-logout if deactivated)

### Admin Side (admin.html)
**Listens to:**
- `bookings` (all bookings)
- `partners` (all partners)

**Updates on:** New bookings, partner online status changes

### Superadmin Side (superadmin.html)
**Listens to:**
- `partners` (tsytaxi-7e9b0)
- `bookings` (tsytaxi-fcbd3)

**Updates on:** Partner changes, booking counts

---

## Summary: Data Across All Pages

### Customer Data Stored:
✅ **users collection** (tsytaxi-fcbd3)
✅ **bookings.passenger** field
✅ **localStorage.tsyTaxiUser**

### Partner Data Stored:
✅ **partners collection** (tsytaxi-7e9b0)
✅ **bookings.partnerId/partnerName/partnerPhone/partnerVehicle** fields
✅ **localStorage.tsyPartnerSession**

### Booking Data Stored:
✅ **bookings collection** (tsytaxi-fcbd3)
✅ Auto-deleted when COMPLETED/CANCELLED/TIMEOUT

### Revenue Data:
✅ Calculated from bookings history before deletion
✅ Displayed in partner dashboard and superadmin

---

## Testing Checklist

- [ ] Customer books → Data appears in users + bookings collections
- [ ] Admin assigns partner → Booking updated with partner details
- [ ] Partner accepts → Status changes, customer sees update
- [ ] Partner arrives → Customer gets notification popup
- [ ] Partner completes → Booking deleted, revenue updates
- [ ] Partner logout/login → Session persists
- [ ] Superadmin blocks partner → Partner sees blocked screen
- [ ] Superadmin views customer → Shows trip count + total spent
- [ ] Admin dashboard → COMPLETED bookings auto-delete
- [ ] Admin dashboard → PENDING > 5min bookings auto-delete

---

## Firestore Console Paths

**Partners:**
https://console.firebase.google.com/project/tsytaxi-7e9b0/firestore/data/partners

**Users:**
https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/data/users

**Bookings:**
https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/data/bookings

---

**All customer data stored perfectly in Firestore!**
