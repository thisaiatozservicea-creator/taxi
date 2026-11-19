# Firestore Rules - Quick Reference

## 🔥 Bookings Database (tsytaxi-fcbd3)

### `users/{userId}` Collection

| Operation | Who Can Do It | Conditions |
|-----------|---------------|------------|
| **Read** | ✅ Owner OR Any authenticated user | `userId == auth.uid` OR `auth != null` |
| **Create** | ✅ Owner only | `userId == auth.uid` + has name & phone |
| **Update** | ✅ Owner only | `userId == auth.uid` + name & phone are strings |
| **Delete** | ✅ Owner only | `userId == auth.uid` |

---

### `bookings/{bookingId}` Collection

| Operation | Who Can Do It | Conditions |
|-----------|---------------|------------|
| **Create** | ✅ Authenticated users | Must have: userId, pickup, destination, fare, status<br>• fare >= 0<br>• distanceKm >= 0<br>• status = "PENDING"<br>• userId = auth.uid<br>• createdAt = now |
| **Read** | ✅ Any authenticated user | No restrictions (needed for partner/admin) |
| **Update** | ✅ Owner (cancel)<br>✅ Any auth user (status changes) | **Customer:** Can cancel their booking<br>**Partner/Admin:** Can update status if transition valid |
| **Delete** | ✅ Any authenticated user | Only if status = CANCELLED or REJECTED |

**Valid Status Transitions:**
```
PENDING     → ASSIGNED, CANCELLED
ASSIGNED    → ACCEPTED, REJECTED, CANCELLED  
ACCEPTED    → IN_PROGRESS, CANCELLED
IN_PROGRESS → COMPLETED, CANCELLED
COMPLETED   → (none)
CANCELLED   → (none)
REJECTED    → (none)
```

---

### `trips/{tripId}` Collection

| Operation | Who Can Do It | Conditions |
|-----------|---------------|------------|
| **Create** | ✅ Authenticated users | status = "COMPLETED"<br>Has: partnerId, userId, fare, distanceKm, completedAt<br>fare & distanceKm are numbers |
| **Read** | ✅ Owner OR Partner OR Any auth | userId = auth.uid OR partnerId exists OR any authenticated |
| **Update** | ✅ Authenticated users | ⚠️ Limited: status must stay COMPLETED<br>fare & partnerId cannot change |
| **Delete** | ❌ BLOCKED | Trip history cannot be deleted |

---

## 🚗 Partners Database (tsytaxi-7e9b0)

### `partners/{partnerId}` Collection

| Operation | Who Can Do It | Conditions |
|-----------|---------------|------------|
| **Read** | ✅ Anyone (public) | No restrictions (needed for login) |
| **Create** | ✅ Anyone | partnerId & active fields required<br>partnerId > 0 chars<br>active = true |
| **Update** | ✅ Partner OR Any auth | ⚠️ Cannot change: partnerId, createdAt<br>✅ Can change: name, phone, vehicle, location<br>Password: must be >= 6 chars if updating |
| **Delete** | ✅ Authenticated users | Any authenticated user (admin in production) |

---

### `partnerRequests/{requestId}` Collection

| Operation | Who Can Do It | Conditions |
|-----------|---------------|------------|
| **Create** | ✅ Anyone (public) | Must have: name, phone<br>name > 0 chars<br>phone >= 10 chars<br>status = "pending"<br>createdAt = now |
| **Read** | ✅ Anyone (public) | No restrictions (admin needs to view) |
| **Update** | ✅ Anyone | Only status & reviewedAt can change<br>status must be: Approved, Rejected, approved, rejected |
| **Delete** | ✅ Anyone (public) | No restrictions (admin cleanup) |

---

## 🎯 Common Operations

### ✅ Allowed

```javascript
// Customer creates booking
await setDoc(doc(db, "bookings", id), {
  userId: auth.uid,
  pickup: {lat: 8.33, lon: 77.86, displayName: "Place A"},
  destination: {lat: 8.35, lon: 77.88, displayName: "Place B"},
  fare: 150,
  distanceKm: 5.2,
  status: "PENDING",
  createdAt: serverTimestamp()
});

// Admin assigns partner
await updateDoc(doc(db, "bookings", id), {
  status: "ASSIGNED",
  partnerId: "TSY001",
  partnerName: "John"
});

// Partner accepts trip
await updateDoc(doc(db, "bookings", id), {
  status: "ACCEPTED",
  acceptedAt: new Date().toISOString()
});

// Partner arrives at pickup
await updateDoc(doc(db, "bookings", id), {
  status: "IN_PROGRESS",
  arrivedAt: new Date().toISOString()
});

// Partner completes trip
await updateDoc(doc(db, "bookings", id), {
  status: "COMPLETED",
  completedAt: new Date().toISOString()
});

// Save to trip history
await setDoc(doc(db, "trips", id), {
  ...bookingData,
  status: "COMPLETED",
  completedAt: new Date().toISOString()
});

// Partner updates profile
await updateDoc(doc(db, "partners", partnerId), {
  phone: "9876543210",
  vehicleNumber: "TN01AB1234",
  email: "partner@example.com"
});

// Submit partner request
await setDoc(doc(db, "partnerRequests", id), {
  name: "New Partner",
  phone: "9876543210",
  status: "pending",
  createdAt: serverTimestamp()
});
```

---

### ❌ Blocked

```javascript
// ❌ Invalid status jump
await updateDoc(doc(db, "bookings", id), {
  status: "COMPLETED"  // Cannot go PENDING → COMPLETED directly
});

// ❌ Negative fare
await setDoc(doc(db, "bookings", id), {
  fare: -100  // Must be >= 0
});

// ❌ Delete trip history
await deleteDoc(doc(db, "trips", id));  // BLOCKED

// ❌ Modify completed trip fare
await updateDoc(doc(db, "trips", id), {
  fare: 200  // Cannot change fare
});

// ❌ Change partner ID
await updateDoc(doc(db, "partners", partnerId), {
  partnerId: "DIFFERENT_ID"  // partnerId is immutable
});

// ❌ Invalid request status
await updateDoc(doc(db, "partnerRequests", id), {
  status: "InvalidStatus"  // Must be Approved/Rejected
});
```

---

## 🔍 Testing Commands

```bash
# Start emulator
firebase emulators:start --only firestore

# Deploy bookings rules
firebase use tsytaxi-fcbd3
firebase deploy --only firestore:rules

# Deploy partners rules
firebase use tsytaxi-7e9b0
firebase deploy --only firestore:rules

# View active rules
firebase firestore:rules --project tsytaxi-fcbd3
firebase firestore:rules --project tsytaxi-7e9b0
```

---

## 📊 Security Levels

| Feature | Implemented | Notes |
|---------|-------------|-------|
| Authentication Required | ✅ | Most operations need auth |
| Data Validation | ✅ | Type checking, range validation |
| Status Transition Control | ✅ | Prevents invalid state changes |
| Immutable Fields | ✅ | partnerId, fare in history |
| Trip History Protection | ✅ | Cannot delete completed trips |
| Rate Limiting | ❌ | Implement in Cloud Functions |
| Admin Role Check | ⚠️ | Uses `if true` - add roles in production |
| Field Encryption | ❌ | Implement for sensitive data |

---

## ⚠️ Production TODOs

1. **Add Firebase Authentication** - Replace public access
2. **Implement role-based access** - Admin, partner, customer roles
3. **Add rate limiting** - Prevent abuse
4. **Enable audit logs** - Track all operations
5. **Hash passwords** - Never store plain text
6. **Add field encryption** - For sensitive data

---

## 🆘 Quick Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| "Missing or insufficient permissions" | Not authenticated | Ensure `auth.currentUser` exists |
| "Invalid status transition" | Skipping states | Follow: PENDING→ASSIGNED→ACCEPTED→IN_PROGRESS→COMPLETED |
| "Validation failed" | Bad data | Check: fare>=0, distanceKm>=0, required fields present |
| Rules not updating | Cache | Wait 1-2 min or `--force` deploy |

---

## 📁 File Locations

```
tsytaxi/
├── firestore.rules                    # Bookings DB (tsytaxi-fcbd3)
├── firestore-partners.rules           # Partners DB (tsytaxi-7e9b0)
├── FIRESTORE_RULES_PRODUCTION.md      # Full deployment guide
└── RULES_REFERENCE.md                 # This file (quick ref)
```

---

**Deploy both rules → Test all operations → Monitor for errors → Implement Firebase Auth for full security**
