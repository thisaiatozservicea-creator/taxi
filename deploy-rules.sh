#!/bin/bash

# TSY TAXI Firestore Rules Deployment Script
# Deploys security rules to both Firebase projects

set -e  # Exit on error

echo "=========================================="
echo "TSY TAXI - Firestore Rules Deployment"
echo "=========================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

echo "✓ Firebase CLI found"
echo ""

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase..."
    firebase login
fi

echo "✓ Firebase authenticated"
echo ""

# Backup current rules
echo "📦 Backing up current rules..."
mkdir -p backups
cp firestore.rules "backups/firestore.rules.$(date +%Y%m%d_%H%M%S).backup" 2>/dev/null || true
cp firestore-partners.rules "backups/firestore-partners.rules.$(date +%Y%m%d_%H%M%S).backup" 2>/dev/null || true
echo "✓ Backup complete"
echo ""

# Deploy to Bookings Database (tsytaxi-fcbd3)
echo "=========================================="
echo "1️⃣  DEPLOYING TO BOOKINGS DATABASE"
echo "=========================================="
echo "Project: tsytaxi-fcbd3"
echo "Rules: firestore.rules"
echo ""

read -p "Deploy bookings rules? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firebase use tsytaxi-fcbd3
    firebase deploy --only firestore:rules
    echo "✅ Bookings rules deployed successfully!"
else
    echo "⏭️  Skipped bookings rules"
fi

echo ""

# Deploy to Partners Database (tsytaxi-7e9b0)
echo "=========================================="
echo "2️⃣  DEPLOYING TO PARTNERS DATABASE"
echo "=========================================="
echo "Project: tsytaxi-7e9b0"
echo "Rules: firestore-partners.rules"
echo ""

# Temporarily swap rules file
read -p "Deploy partners rules? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup main rules and use partners rules
    cp firestore.rules firestore.rules.temp
    cp firestore-partners.rules firestore.rules

    firebase use tsytaxi-7e9b0
    firebase deploy --only firestore:rules

    # Restore main rules
    cp firestore.rules.temp firestore.rules
    rm firestore.rules.temp

    echo "✅ Partners rules deployed successfully!"
else
    echo "⏭️  Skipped partners rules"
fi

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo "1. Test operations in your app"
echo "2. Monitor Firebase Console for errors"
echo "3. Check rules at:"
echo "   - https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/rules"
echo "   - https://console.firebase.google.com/project/tsytaxi-7e9b0/firestore/rules"
echo ""
echo "📚 Documentation:"
echo "   - Full guide: FIRESTORE_RULES_PRODUCTION.md"
echo "   - Quick ref: RULES_REFERENCE.md"
echo ""
