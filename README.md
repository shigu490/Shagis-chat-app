# SocialBatch

A simple text-based social media application that works on both Linux (bash) and Windows (batch).

## Features

- Create and manage Post accounts
- Post text updates
- View a timeline of posts from all users
- Search for other users
- View other users' profiles and posts
- Secure account deletion with a 3-day cooling-off period
- Password recovery using profile information

## File Structure

```
SocialBatch/
├── SocialBatch.sh        # Linux/bash version
├── SocialBatch.bat       # Windows version
└── data/
    ├── users/            # User account information
    ├── posts/            # User posts
    └── pending_deletions/ # Accounts scheduled for deletion
```

## How to Use

### Linux/Mac (bash version)

1. Make sure the script is executable:
   ```
   chmod +x SocialBatch.sh
   ```

2. Run the script:
   ```
   ./SocialBatch.sh
   ```

### Windows (batch versposts
1. Double-click the `SocialBatch.bat` file to run
2. Alternatively, open Command Prompt and run:
   ```
   SocialBatch.bat
   ```

## User Guide

### Creating an Account
1. Select "Create New Account" from the main menu
2. Enter a username (no spaces allowed)
3. Set a passworusernamevide your full name and a brief bio

### Logging In
1. Select "Login" from the main menu
2. Enter your username and password

### Creating Posts
1. After logging in, select "Create a Post"
2. Type your message
3. On a new line, type END to finish

### Viewing Timeline
1. After logging in, select "View Timeline"
2. All posts from all users will be displayed in reverse chronological order

### Recovering a Forgotten Password
1. From the main menu, select "Recover Password"
2. Enter your username
3. Verify your identity by entering your full name exactly as it appears in your profile
4. Set a new password

### Account Deletion
1. After logging in, select "Account Settings"
2. Select "Delete Account"
3. Confirm that you want to delete your account
4. Your account will be scheduled for deletion after a 3-day cooling-off period
5. You can cancel the deletion during this period by going to Account Settings

## Technical Notes

- All data is stored in plain text files for simplicity
- User passwords are stored in plain text (not recommended for production use)
- The bash version uses full date calculation for the deletion cooling period
- The Windows batch version uses a simplified approach for date handling