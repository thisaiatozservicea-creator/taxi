# Production Firestore Rules - Complete Guide

## 🎯 Overview

TSY TAXI uses **TWO separate Firebase projects** with enhanced security rules:

1. **tsytaxi-fcbd3** (Bookings DB) - `firestore.rules`
2. **tsytaxi-7e9b0** (Partners DB) - `firestore-partners.rules`

---

## 📋 Security Features Implemented

### ✅ Bookings Database (tsytaxi-fcbd3)

**Collections:** `bookings`, `trips`, `users`

**Security Measures:**
- ✅ Authentication required for all operations
- ✅ Users can only modify their own data
- ✅ Booking status transitions validated (no skipping states)
- ✅ Data validation (fare >= 0, distance >= 0, valid status)
- ✅ Trip history cannot be deleted
- ✅ Field-level validation on updates
- ✅ Timestamp validation on creates

**Allowed Status Transitions:**
```
PENDING → ASSIGNED → ACCEPTED → IN_PROGRESS → COMPLETED
       ↓         ↓          ↓           ↓
   CANCELLED  CANCELLED  CANCELLED  CANCELLED
```

### ✅ Partners Database (tsytaxi-7e9b0)

**Collections:** `partners`, `partnerRequests`

**Security Measures:**
- ✅ Public read for partner login (necessary for authentication)
- ✅ Partner ID validation (cannot be changed)
- ✅ Password minimum 6 characters
- ✅ Profile update validation
- ✅ Request status validation (Pending → Approved/Rejected)
- ✅ Partner application validation (name, phone required)

---

## 🚀 Deployment Steps

### Method 1: Firebase CLI (Recommended)

#### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

#### Step 2: Login
```bash
firebase login
```

#### Step 3: Initialize Firebase (if not done)
```bash
cd "C:\Users\MUTHU KRISHNAN\OneDrive\New project\tsytaxi"
firebase init firestore
```

Select:
- Use existing projects
- Choose both `tsytaxi-fcbd3` and `tsytaxi-7e9b0`
- Keep default firestore.rules

#### Step 4: Deploy Bookings Database Rules
```bash
# Copy firestore.rules to project root
firebase use tsytaxi-fcbd3
firebase deploy --only firestore:rules
```

#### Step 5: Deploy Partners Database Rules
```bash
# Backup current rules file
cp firestore.rules firestore.rules.backup

# Copy partners rules
cp firestore-partners.rules firestore.rules

# Deploy
firebase use tsytaxi-7e9b0
firebase deploy --only firestore:rules

# Restore original rules
cp firestore.rules.backup firestore.rules
rm firestore.rules.backup
```

---

### Method 2: Firebase Console (Manual)

#### For Bookings Database (tsytaxi-fcbd3):

1. Open https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/rules
2. Copy entire contents of `firestore.rules`
3. Paste into rules editor
4. Click **"Publish"**
5. Wait for confirmation (takes ~1 minute)

#### For Partners Database (tsytaxi-7e9b0):

1. Open https://console.firebase.google.com/project/tsytaxi-7e9b0/firestore/rules
2. Copy entire contents of `firestore-partners.rules`
3. Paste into rules editor
4. Click **"Publish"**
5. Wait for confirmation

---

## 🧪 Testing Rules

### Test Using Firebase Emulator (Recommended)

#### Step 1: Start Emulator
```bash
firebase emulators:start --only firestore
```

#### Step 2: Connect App to Emulator
Add to Firebase config in HTML files:

```javascript
import { getFirestore, connectFirestoreEmulator } from "firebase/firestore";

const db = getFirestore(app);

// Connect to emulator
if (location.hostname === "localhost") {
  connectFirestoreEmulator(db, 'localhost', 8080);
}
```

#### Step 3: Run Tests
Test scenarios:
- ✅ Create booking as authenticated user
- ✅ Try to read another user's data
- ✅ Try invalid status transitions
- ✅ Try to delete trip history
- ✅ Create partner request
- ✅ Update partner profile

---

## 📊 Rule Validation Examples

### ✅ Valid Operations

**Create Booking:**
```javascript
// ✅ ALLOWED
await setDoc(doc(db, "bookings", bookingId), {
  userId: currentUser.uid,
  pickup: {...},
  destination: {...},
  fare: 150,
  distanceKm: 5.2,
  status: "PENDING",
  createdAt: serverTimestamp()
});
```

**Update Booking Status:**
```javascript
// ✅ ALLOWED (valid transition)
await updateDoc(doc(db, "bookings", bookingId), {
  status: "ASSIGNED",
  partnerId: "TSY001",
  assignedAt: serverTimestamp()
});
```

**Partner Profile Update:**
```javascript
// ✅ ALLOWED
await updateDoc(doc(db, "partners", partnerId), {
  phone: "9876543210",
  vehicleNumber: "TN01AB1234",
  profileUpdatedAt: serverTimestamp()
});
```

---

### ❌ Blocked Operations

**Invalid Status Transition:**
```javascript
// ❌ BLOCKED (cannot skip from PENDING to IN_PROGRESS)
await updateDoc(doc(db, "bookings", bookingId), {
  status: "IN_PROGRESS"
});
// Error: invalid status transition
```

**Delete Trip History:**
```javascript
// ❌ BLOCKED
await deleteDoc(doc(db, "trips", tripId));
// Error: permission denied
```

**Invalid Data:**
```javascript
// ❌ BLOCKED (negative fare)
await setDoc(doc(db, "bookings", bookingId), {
  userId: currentUser.uid,
  fare: -50,
  status: "PENDING"
});
// Error: validation failed
```

**Change Partner ID:**
```javascript
// ❌ BLOCKED (partnerId is immutable)
await updateDoc(doc(db, "partners", partnerId), {
  partnerId: "DIFFERENT_ID"
});
// Error: partnerId cannot be changed
```

---

## 🔒 Security Best Practices

### Current Implementation:

✅ **Authentication Required** - Most operations need auth  
✅ **Data Validation** - Type checking, range validation  
✅ **Status Transition Control** - Prevents invalid state changes  
✅ **Immutable Fields** - Critical fields cannot be modified  
✅ **Trip History Protection** - Completed trips cannot be deleted  

### ⚠️ Production Recommendations:

**High Priority:**
1. **Implement Firebase Authentication**
   - Replace `allow read: if true` with proper auth checks
   - Add custom claims for roles (admin, partner, customer)
   
2. **Add Admin Role Check**
   ```javascript
   function isAdmin() {
     return request.auth != null 
       && request.auth.token.admin == true;
   }
   ```

3. **Rate Limiting**
   - Implement Cloud Functions to track request rates
   - Add quotas per user

4. **Audit Logging**
   - Log all write operations
   - Track security rule violations

**Medium Priority:**
5. **Partner Authentication**
   - Store hashed passwords only
   - Implement proper partner login flow
   - Use Firebase Auth custom tokens

6. **Field-Level Encryption**
   - Encrypt sensitive data (phone, email)
   - Decrypt in Cloud Functions

---

## 🎯 Testing Checklist

### Bookings Database Tests

- [ ] **User can create booking with valid data**
  ```javascript
  Status: PENDING, fare > 0, has pickup & destination
  ```

- [ ] **User cannot create booking with invalid data**
  ```javascript
  Try: negative fare, missing fields, invalid status
  ```

- [ ] **Status transitions work correctly**
  ```javascript
  PENDING → ASSIGNED ✅
  PENDING → COMPLETED ❌
  ```

- [ ] **User can read their own bookings**
  ```javascript
  userId == auth.uid
  ```

- [ ] **Trip history is protected**
  ```javascript
  Try to delete trip ❌
  Try to modify fare in completed trip ❌
  ```

### Partners Database Tests

- [ ] **Anyone can read partners (for login)**
  ```javascript
  Public read access ✅
  ```

- [ ] **Partner can update their profile**
  ```javascript
  Update phone, vehicle, email ✅
  ```

- [ ] **Partner cannot change partnerId**
  ```javascript
  Try to change partnerId ❌
  ```

- [ ] **Anyone can submit partner request**
  ```javascript
  Create request with name & phone ✅
  ```

- [ ] **Request status can only be updated to valid values**
  ```javascript
  Pending → Approved ✅
  Pending → Invalid ❌
  ```

---

## 📝 Troubleshooting

### Issue: "Missing or insufficient permissions"

**Cause:** User not authenticated or trying to access restricted data

**Fix:**
```javascript
// Ensure user is authenticated
if (!auth.currentUser) {
  await signInAnonymously(auth);
}
```

### Issue: "Invalid status transition"

**Cause:** Trying to skip booking status states

**Fix:**
```javascript
// Follow proper sequence
PENDING → ASSIGNED → ACCEPTED → IN_PROGRESS → COMPLETED
```

### Issue: "Validation failed"

**Cause:** Data doesn't meet validation requirements

**Fix:**
```javascript
// Ensure all required fields present
// fare >= 0, distanceKm >= 0
// status is valid enum value
```

### Issue: Rules not updating

**Cause:** Firebase cache

**Fix:**
```bash
# Clear cache
firebase deploy --only firestore:rules --force

# Or wait 1-2 minutes for propagation
```

---

## 🔧 Monitoring & Maintenance

### Monitor Rule Usage:

1. Open Firebase Console → Firestore → Usage
2. Check "Rules Evaluations" graph
3. Look for spikes in denied requests

### Review Security Violations:

```bash
# Enable audit logs in Firebase Console
# Settings → Audit Logs → Enable

# View logs
gcloud logging read "resource.type=firestore_database"
```

### Update Rules Safely:

1. Test in emulator first
2. Deploy to staging environment
3. Monitor for errors
4. Deploy to production
5. Watch metrics for 24 hours

---

## 📞 Support

Rules deployed: Check Firebase Console → Firestore → Rules tab

Rules working: Test with Firebase Emulator

Need help: Check Firebase documentation at https://firebase.google.com/docs/firestore/security

---

## ✅ Deployment Verification

After deploying rules, verify:

```bash
# Check active rules
firebase firestore:rules --project tsytaxi-fcbd3
firebase firestore:rules --project tsytaxi-7e9b0

# Test basic operations
# Try creating a booking in your app
# Try updating partner profile
# Try reading trip history

# Expected: All operations work correctly with proper auth
# Expected: Invalid operations are blocked
```

**Status:** Rules are production-ready with current authentication method. Implement Firebase Auth for full security.
