@echo off
REM TSY TAXI Firestore Rules Deployment Script (Windows)
REM Deploys security rules to both Firebase projects

echo ==========================================
echo TSY TAXI - Firestore Rules Deployment
echo ==========================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo Firebase CLI not found. Installing...
    npm install -g firebase-tools
)

echo Firebase CLI found
echo.

REM Check if user is logged in
firebase projects:list >nul 2>nul
if %errorlevel% neq 0 (
    echo Please login to Firebase...
    firebase login
)

echo Firebase authenticated
echo.

REM Backup current rules
echo Backing up current rules...
if not exist backups mkdir backups
set timestamp=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
copy firestore.rules "backups\firestore.rules.%timestamp%.backup" >nul 2>nul
copy firestore-partners.rules "backups\firestore-partners.rules.%timestamp%.backup" >nul 2>nul
echo Backup complete
echo.

REM Deploy to Bookings Database
echo ==========================================
echo 1. DEPLOYING TO BOOKINGS DATABASE
echo ==========================================
echo Project: tsytaxi-fcbd3
echo Rules: firestore.rules
echo.

set /p deploy_bookings="Deploy bookings rules? (y/n): "
if /i "%deploy_bookings%"=="y" (
    call firebase use tsytaxi-fcbd3
    call firebase deploy --only firestore:rules
    echo Bookings rules deployed successfully!
) else (
    echo Skipped bookings rules
)

echo.

REM Deploy to Partners Database
echo ==========================================
echo 2. DEPLOYING TO PARTNERS DATABASE
echo ==========================================
echo Project: tsytaxi-7e9b0
echo Rules: firestore-partners.rules
echo.

set /p deploy_partners="Deploy partners rules? (y/n): "
if /i "%deploy_partners%"=="y" (
    REM Temporarily swap rules file
    copy firestore.rules firestore.rules.temp >nul
    copy firestore-partners.rules firestore.rules >nul

    call firebase use tsytaxi-7e9b0
    call firebase deploy --only firestore:rules

    REM Restore main rules
    copy firestore.rules.temp firestore.rules >nul
    del firestore.rules.temp

    echo Partners rules deployed successfully!
) else (
    echo Skipped partners rules
)

echo.
echo ==========================================
echo DEPLOYMENT COMPLETE
echo ==========================================
echo.
echo Next Steps:
echo 1. Test operations in your app
echo 2. Monitor Firebase Console for errors
echo 3. Check rules at:
echo    - https://console.firebase.google.com/project/tsytaxi-fcbd3/firestore/rules
echo    - https://console.firebase.google.com/project/tsytaxi-7e9b0/firestore/rules
echo.
echo Documentation:
echo    - Full guide: FIRESTORE_RULES_PRODUCTION.md
echo    - Quick ref: RULES_REFERENCE.md
echo.
pause
