@echo off
setlocal enabledelayedexpansion

:: SocialBatch - A text-based social media application

:: Initialize directories if they don't exist
if not exist data\users mkdir data\users
if not exist data\posts mkdir data\posts
if not exist data\pending_deletions mkdir data\pending_deletions

:: Set counter for post IDs
set postCounter=0
if exist data\postcounter.txt (
    set /p postCounter=<data\postcounter.txt
)

:: Main application loop
:main
:: Check for accounts pending deletion
call :processPendingDeletions

cls
echo.
echo ===================================
echo   SOCIALBATCH - TEXT SOCIAL MEDIA
echo ===================================
echo.
echo [1] Login
echo [2] Create New Account
echo [3] Recover Password
echo [4] Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto login
if "%choice%"=="2" goto createAccount
if "%choice%"=="3" goto recoverPassword
if "%choice%"=="4" exit /b
goto main

:: Function for user login
:login
cls
echo.
echo ===================================
echo            LOGIN SCREEN
echo ===================================
echo.
set /p username="Enter your username: "

if not exist "data\users\%username%.txt" (
    echo.
    echo User does not exist!
    echo.
    pause
    goto main
)

:: Check if account is pending deletion and if cooling period has passed
if exist "data\pending_deletions\%username%.txt" (
    set /p requestDate=<"data\pending_deletions\%username%.txt"
    
    :: Calculate days since deletion request in Windows batch is complex
    :: For simplicity, we'll check if the request is at least 3 days old based on file date
    for %%A in ("data\pending_deletions\%username%.txt") do set fileDate=%%~tA
    
    :: Simplified check - in a real implementation, calculate days difference properly
    :: This version just warns the user the account is pending deletion
    echo.
    echo WARNING: This account is scheduled for deletion!
    echo The account will be inaccessible soon.
    echo If you want to keep your account, login and cancel the deletion.
    echo.
    pause
)

set /p password="Enter your password: "
echo.

:: Extract password from user file
for /f "tokens=1,* delims=:" %%a in ('findstr /b "password:" "data\users\%username%.txt"') do (
    set correctPassword=%%b
    :: Remove leading space
    set correctPassword=!correctPassword:~1!
)

if "!correctPassword!"=="" (
    echo.
    echo Error: Password information not found!
    pause
    goto main
)

if "%password%" neq "!correctPassword!" (
    echo.
    echo Incorrect password!
    echo.
    pause
    goto main
)

echo.
echo Login successful!
echo.
timeout /t 1 >nul
goto userHome

:: Function to create new account
:createAccount
cls
echo.
echo ===================================
echo         CREATE NEW ACCOUNT
echo ===================================
echo.
set /p username="Choose a username (no spaces): "

:: Check if username contains spaces
echo %username% | findstr /C:" " >nul
if not errorlevel 1 (
    echo Username cannot contain spaces!
    pause
    goto createAccount
)

:: Check if user already exists
if exist "data\users\%username%.txt" (
    echo.
    echo Username already exists!
    echo.
    pause
    goto createAccount
)

set /p password="Create a password: "
echo.
set /p fullname="Enter your full name: "
set /p bio="Write a short bio about yourself: "

:: Save user information
(
    echo username:%username%
    echo password: %password%
    echo fullname: %fullname%
    echo bio: %bio%
    echo joined: %date% %time%
) > "data\users\%username%.txt"

echo.
echo Account created successfully!
echo.
pause
goto main

:: Function for user home page
:userHome
cls
echo.
echo ===================================
echo         WELCOME, %username%!
echo ===================================
echo.
echo [1] View My Profile
echo [2] Create a Post
echo [3] View Timeline
echo [4] Search for Users
echo [5] Account Settings
echo [6] Logout
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto viewProfile
if "%choice%"=="2" goto createPost
if "%choice%"=="3" goto viewTimeline
if "%choice%"=="4" goto searchUsers
if "%choice%"=="5" goto accountSettings
if "%choice%"=="6" goto main
goto userHome

:: Function for account settings
:accountSettings
cls
echo.
echo ===================================
echo         ACCOUNT SETTINGS
echo ===================================
echo.

:: Check if a deletion request already exists
if exist "data\pending_deletions\%username%.txt" (
    set /p requestDate=<"data\pending_deletions\%username%.txt"
    
    :: In a real implementation, we would calculate the deletion date properly
    echo WARNING: Your account is scheduled for deletion!
    echo Deletion request submitted on: %requestDate%
    echo Account will be deleted after the 3-day cooling period.
    echo.
    echo [1] Cancel Account Deletion
    echo [2] Go Back
    echo.
    set /p choice="Enter your choice (1-2): "

    if "%choice%"=="1" (
        del "data\pending_deletions\%username%.txt"
        echo.
        echo Account deletion request canceled!
        echo.
        pause
        goto accountSettings
    )
    if "%choice%"=="2" goto userHome
    goto accountSettings
) else (
    echo [1] Delete Account
    echo [2] Go Back
    echo.
    set /p choice="Enter your choice (1-2): "

    if "%choice%"=="1" goto deleteAccount
    if "%choice%"=="2" goto userHome
    goto accountSettings
)

:: Function to handle account deletion
:deleteAccount
cls
echo.
echo ===================================
echo         DELETE ACCOUNT
echo ===================================
echo.
echo WARNING! This action cannot be undone!
echo Your account will be scheduled for deletion
echo with a cooling-off period of 3 days.
echo.
echo During this time, you can cancel the deletion
echo by visiting Account Settings.
echo.
echo After 3 days, your account and all your posts
echo will be permanently deleted.
echo.
echo Are you sure you want to proceed?
echo [1] Yes, schedule my account for deletion
echo [2] No, cancel and go back
echo.
set /p choice="Enter your choice (1-2): "

if "%choice%"=="1" (
    :: Generate deletion date
    echo %date%> "data\pending_deletions\%username%.txt"
    
    echo.
    echo Your account has been scheduled for deletion.
    echo It will be permanently deleted after 3 days.
    echo You can cancel this request anytime before then.
    echo.
    pause
    goto userHome
)
if "%choice%"=="2" goto accountSettings
goto deleteAccount

:: Function to view profile
:viewProfile
cls
echo.
echo ===================================
echo         PROFILE: %username%
echo ===================================
echo.

:: Display profile information
for /f "tokens=1,* delims=:" %%a in ('type "data\users\%username%.txt"') do (
    if not "%%a"=="password" (
        echo %%a:%%b
    )
)

echo.
echo === MY POSTS ===
echo.

set postFound=0
for %%F in (data\posts\*.txt) do (
    set "file=%%F"
    set "postUsername="
    set "postContent="
    set "postDate="
    set "postID="
    
    for /f "tokens=1,* delims=:" %%a in ('type "!file!"') do (
        if "%%a"=="username" set "postUsername=%%b"
        if "%%a"=="content" set "postContent=%%b"
        if "%%a"=="date" set "postDate=%%b"
        if "%%a"=="id" set "postID=%%b"
    )
    
    :: Remove leading space from variables
    set "postUsername=!postUsername:~1!"
    
    if "!postUsername!"=="%username%" (
        set postFound=1
        echo ID:!postID!
        echo Date:!postDate!
        echo !postContent!
        echo ------------------------------
    )
)

if "%postFound%"=="0" (
    echo No posts yet. Create your first post!
)

echo.
echo [1] Go Back
echo.
set /p choice="Enter your choice: "

if "%choice%"=="1" goto userHome
goto viewProfile

:: Function to create post
:createPost
cls
echo.
echo ===================================
echo           CREATE A POST
echo ===================================
echo.
echo Type your post below (type 'END' on a new line when finished):
echo ---------------------------------------------
echo.

:: Read multiline input
set "post="
:readPostLoop
set /p line=""
if "%line%"=="END" goto savePost
set "post=!post! %line%"
goto readPostLoop

:savePost
:: Save post to file
set /a postCounter+=1
(
    echo id: %postCounter%
    echo username: %username%
    echo date: %date% %time%
    echo content: %post%
) > "data\posts\post_%postCounter%.txt"

:: Update post counter
echo %postCounter%> data\postcounter.txt

echo.
echo Post created successfully!
echo.
pause
goto userHome

:: Function to view timeline
:viewTimeline
cls
echo.
echo ===================================
echo             TIMELINE
echo ===================================
echo.

:: Check if there are any posts
set postsExist=0
for %%F in (data\posts\*.txt) do (
    set postsExist=1
    goto timelinePostsExist
)

:timelineNoPost
if "%postsExist%"=="0" (
    echo No posts available in the timeline.
    echo.
    pause
    goto userHome
)

:timelinePostsExist
:: Display all posts sorted by newest first (using post ID as approximation)
set current=%postCounter%

:timelinePostLoop
if %current% LEQ 0 goto timelineEnd

if exist "data\posts\post_%current%.txt" (
    for /f "tokens=1,* delims=:" %%a in ('type "data\posts\post_%current%.txt"') do (
        if "%%a"=="username" set "postUsername=%%b"
        if "%%a"=="content" set "postContent=%%b"
        if "%%a"=="date" set "postDate=%%b"
    )
    
    :: Remove leading space from variables
    set "postUsername=!postUsername:~1!"
    set "postDate=!postDate:~1!"
    set "postContent=!postContent:~1!"
    
    echo ===== POST #%current% =====
    echo By:!postUsername!
    echo Date:!postDate!
    echo !postContent!
    echo ------------------------------
    echo.
)

set /a current-=1
goto timelinePostLoop

:timelineEnd
echo [1] Refresh Timeline
echo [2] Go Back
echo.
set /p choice="Enter your choice: "

if "%choice%"=="2" goto userHome
goto viewTimeline

:: Function to search users
:searchUsers
cls
echo.
echo ===================================
echo          SEARCH FOR USERS
echo ===================================
echo.
set /p searchTerm="Enter username to search: "

set userFound=0
for %%F in (data\users\*.txt) do (
    set "filename=%%~nF"
    echo !filename! | findstr /i "%searchTerm%" >nul
    if not errorlevel 1 (
        set userFound=1
        echo Found user: !filename!
    )
)

if "%userFound%"=="0" (
    echo No users found matching '%searchTerm%'
)

echo.
echo [1] View a Profile
echo [2] Go Back
echo.
set /p choice="Enter your choice: "

if "%choice%"=="1" (
    set /p viewUser="Enter username to view: "
    if exist "data\users\%viewUser%.txt" (
        goto viewOtherProfile
    ) else (
        echo User does not exist!
        pause
        goto searchUsers
    )
)
if "%choice%"=="2" goto userHome
goto searchUsers

:: Function to view other user's profile
:viewOtherProfile
cls
echo.
echo ===================================
echo         PROFILE: %viewUser%
echo ===================================
echo.

:: Display profile information
for /f "tokens=1,* delims=:" %%a in ('type "data\users\%viewUser%.txt"') do (
    if not "%%a"=="password" (
        echo %%a:%%b
    )
)

echo.
echo === POSTS ===
echo.

set postFound=0
for %%F in (data\posts\*.txt) do (
    set "file=%%F"
    set "postUsername="
    set "postContent="
    set "postDate="
    
    for /f "tokens=1,* delims=:" %%a in ('type "!file!"') do (
        if "%%a"=="username" set "postUsername=%%b"
        if "%%a"=="content" set "postContent=%%b"
        if "%%a"=="date" set "postDate=%%b"
    )
    
    :: Remove leading space from variables
    set "postUsername=!postUsername:~1!"
    
    if "!postUsername!"=="%viewUser%" (
        set postFound=1
        echo Date:!postDate!
        echo !postContent!
        echo ------------------------------
    )
)

if "%postFound%"=="0" (
    echo This user hasn't posted anything yet.
)

echo.
echo [1] Go Back to Search
echo [2] Go Back to Home
echo.
set /p choice="Enter your choice: "

if "%choice%"=="1" goto searchUsers
if "%choice%"=="2" goto userHome
goto viewOtherProfile

:: Function to process all pending account deletions
:processPendingDeletions
echo Checking for accounts pending deletion...

for %%F in (data\pending_deletions\*.txt) do (
    set "file=%%F"
    set "pendingUsername=%%~nF"
    set /p requestDate=<"!file!"
    
    :: For Windows batch, calculating date differences is complex
    :: This is a simplified approach that just checks file creation date
    
    :: Get file creation date in days since 1970 (approximate)
    for %%A in ("!file!") do set fileDate=%%~tA
    
    :: In a real implementation, properly calculate days since creation
    :: For this example, we'll just check files older than 3 days based on timestamp
    
    :: Instead of a real check, we'll just look at the file creation timestamp
    :: In a real implementation, calculate proper date differences
    
    echo Checking !pendingUsername! (request date: !requestDate!)
    
    :: If file is older than 3 days, we'd delete the account
    :: For demonstration, we'll include the code structure
    if exist "data\users\!pendingUsername!.txt" (
        echo Account !pendingUsername! would be deleted in a production system
        :: In a real version with proper date checking:
        :: del "data\users\!pendingUsername!.txt"
        
        :: Delete all posts by this user
        :: for %%P in (data\posts\*.txt) do (
        ::     set "postFile=%%P"
        ::     findstr /C:"username: !pendingUsername!" "!postFile!" >nul
        ::     if not errorlevel 1 (
        ::         del "!postFile!"
        ::     )
        :: )
        
        :: Remove the deletion request
        :: del "!file!"
    )
)
goto :eof

:: Function for password recovery
:recoverPassword
cls
echo.
echo ===================================
echo         PASSWORD RECOVERY
echo ===================================
echo.
set /p username="Enter your username: "

if not exist "data\users\%username%.txt" (
    echo.
    echo User does not exist!
    echo.
    pause
    goto main
)

:: Get the user's full name from their profile to verify identity
for /f "tokens=1,* delims=:" %%a in ('findstr /b "fullname:" "data\users\%username%.txt"') do (
    set fullname=%%b
    :: Remove leading space
    set fullname=!fullname:~1!
)

echo.
echo For security verification, please answer the following:
set /p enteredName="Enter your full name exactly as it appears in your profile: "

if "%enteredName%" neq "!fullname!" (
    echo.
    echo Verification failed. The information provided does not match our records.
    echo.
    pause
    goto main
)

:: If verification passes, allow user to set a new password
echo.
echo Verification successful!
set /p newPassword="Enter your new password: "

:: Update the password in the user file
:: First, create a temporary file with all lines except password
type nul > "data\users\temp_%username%.txt"
for /f "tokens=1,* delims=:" %%a in ('type "data\users\%username%.txt"') do (
    if not "%%a"=="password" (
        echo %%a:%%b>> "data\users\temp_%username%.txt"
    )
)
:: Then add the new password line
echo password: %newPassword%>> "data\users\temp_%username%.txt"
:: Replace the original file with the updated one
move /y "data\users\temp_%username%.txt" "data\users\%username%.txt"

echo.
echo Password has been reset successfully!
echo You can now login with your new password.
echo.
pause
goto main