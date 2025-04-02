#!/bin/bash

# SocialBatch - A text-based social media application for Mac, Linux and Unix systems
# Mac-compatible version

# Initialize directories if they don't exist
mkdir -p data/users
mkdir -p data/posts
mkdir -p data/pending_deletions

# Set counter for post IDs
postCounter=0
if [ -f data/postcounter.txt ]; then
    postCounter=$(cat data/postcounter.txt)
fi

# Function to calculate days between dates (Mac compatible)
# Takes two dates in YYYY-MM-DD format
calculate_days_between() {
    # For Mac compatibility, we use a different approach than Linux's date -d
    # Convert dates to seconds since epoch using date utility available on Mac
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command syntax
        date1=$(date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null)
        date2=$(date -j -f "%Y-%m-%d" "$2" "+%s" 2>/dev/null)
        
        # If date conversion failed, try alternate format that might be stored
        if [ -z "$date1" ]; then
            # Try with format like "Tue Apr 2 20:41:10 EDT 2024"
            date1=$(date -j -f "%a %b %d %T %Z %Y" "$1" "+%s" 2>/dev/null)
        fi
        if [ -z "$date2" ]; then
            date2=$(date -j -f "%a %b %d %T %Z %Y" "$2" "+%s" 2>/dev/null)
        fi
    else
        # Linux date command syntax
        date1=$(date -d "$1" +%s 2>/dev/null)
        date2=$(date -d "$2" +%s 2>/dev/null)
    fi
    
    # If dates couldn't be converted (perhaps due to format issues)
    if [ -z "$date1" ] || [ -z "$date2" ]; then
        echo "0" # Return 0 days as fallback
        return
    fi
    
    # Calculate difference in days
    diff_seconds=$((date2 - date1))
    days=$((diff_seconds / 86400))
    echo "$days"
}

# Get today's date in YYYY-MM-DD format (Mac compatible)
get_today() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date format
        date "+%Y-%m-%d"
    else
        # Linux date format
        date "+%Y-%m-%d"
    fi
}

# Function for user login
login() {
    clear
    echo
    echo "==================================="
    echo "           LOGIN SCREEN"
    echo "==================================="
    echo
    read -p "Enter your username: " username

    if [ ! -f "data/users/$username.txt" ]; then
        echo
        echo "User does not exist!"
        echo
        read -p "Press Enter to continue..."
        main
        return
    fi
    
    # Check if account is pending deletion and if cooling period has passed
    if [ -f "data/pending_deletions/$username.txt" ]; then
        requestDate=$(cat "data/pending_deletions/$username.txt")
        
        # Calculate days since deletion request using the Mac-compatible function
        today=$(get_today)
        daysDiff=$(calculate_days_between "$requestDate" "$today")
        
        if [ "$daysDiff" -ge 3 ]; then
            # Deletion period has passed, delete the account and all posts
            echo
            echo "This account has been deleted."
            echo "The deletion request was made on $requestDate and the"
            echo "3-day cooling-off period has now ended."
            echo
            
            # Delete user file
            rm "data/users/$username.txt"
            
            # Delete all posts by this user
            for file in data/posts/*.txt; do
                if [ -f "$file" ] && [ "$file" != "data/posts/*.txt" ]; then
                    postUsername=$(grep "^username:" "$file" | cut -d':' -f2 | sed 's/^ //')
                    if [ "$postUsername" = "$username" ]; then
                        rm "$file"
                    fi
                fi
            done
            
            # Remove the deletion request
            rm "data/pending_deletions/$username.txt"
            
            read -p "Press Enter to continue..."
            main
            return
        else
            # Warn user about pending deletion
            echo
            echo "WARNING: This account is scheduled for deletion!"
            echo "The account will be inaccessible in $((3 - daysDiff)) days."
            echo "If you want to keep your account, login and cancel the deletion."
            echo
        fi
    fi

    read -p "Enter your password: " password
    echo
    
    correctPassword=$(grep "^password:" "data/users/$username.txt" | cut -d':' -f2)
    
    # Removing leading space if present
    correctPassword=$(echo "$correctPassword" | sed 's/^ //')

    if [ -z "$correctPassword" ]; then
        echo
        echo "Error: Password information not found!"
        read -p "Press Enter to continue..."
        main
        return
    fi

    if [ "$password" != "$correctPassword" ]; then
        echo
        echo "Incorrect password!"
        echo
        read -p "Press Enter to continue..."
        main
        return
    fi

    echo
    echo "Login successful!"
    echo
    sleep 1
    userHome
}

# Function to create new account
createAccount() {
    clear
    echo
    echo "==================================="
    echo "        CREATE NEW ACCOUNT"
    echo "==================================="
    echo
    read -p "Choose a username (no spaces): " username

    # Check if username contains spaces
    if [[ "$username" == *" "* ]]; then
        echo "Username cannot contain spaces!"
        read -p "Press Enter to continue..."
        createAccount
        return
    fi

    # Check if user already exists
    if [ -f "data/users/$username.txt" ]; then
        echo
        echo "Username already exists!"
        echo
        read -p "Press Enter to continue..."
        createAccount
        return
    fi

    read -p "Create a password: " password
    echo
    read -p "Enter your full name: " fullname
    read -p "Write a short bio about yourself: " bio

    # Save user information with current date (Mac compatible)
    echo "username:$username" > "data/users/$username.txt"
    echo "password: $password" >> "data/users/$username.txt"
    echo "fullname: $fullname" >> "data/users/$username.txt"
    echo "bio: $bio" >> "data/users/$username.txt"
    echo "joined: $(date)" >> "data/users/$username.txt"

    echo
    echo "Account created successfully!"
    echo
    read -p "Press Enter to continue..."
    main
}

# Function for user home page
userHome() {
    clear
    echo
    echo "==================================="
    echo "        WELCOME, $username!"
    echo "==================================="
    echo
    echo "[1] View My Profile"
    echo "[2] Create a Post"
    echo "[3] View Timeline"
    echo "[4] Search for Users"
    echo "[5] Account Settings"
    echo "[6] Logout"
    echo
    read -p "Enter your choice (1-6): " choice

    case $choice in
        1) viewProfile ;;
        2) createPost ;;
        3) viewTimeline ;;
        4) searchUsers ;;
        5) accountSettings ;;
        6) main ;;
        *) userHome ;;
    esac
}

# Function for account settings
accountSettings() {
    clear
    echo
    echo "==================================="
    echo "        ACCOUNT SETTINGS"
    echo "==================================="
    echo
    
    # Check if a deletion request already exists
    if [ -f "data/pending_deletions/$username.txt" ]; then
        requestDate=$(cat "data/pending_deletions/$username.txt")
        today=$(get_today)
        daysDiff=$(calculate_days_between "$requestDate" "$today")
        daysLeft=$((3 - daysDiff))
        
        echo "WARNING: Your account is scheduled for deletion!"
        echo "Deletion request submitted on: $requestDate"
        echo "Account will be deleted in $daysLeft day(s)"
        echo
        echo "[1] Cancel Account Deletion"
        echo "[2] Go Back"
        echo
        read -p "Enter your choice (1-2): " choice

        case $choice in
            1) 
                rm "data/pending_deletions/$username.txt"
                echo
                echo "Account deletion request canceled!"
                echo
                read -p "Press Enter to continue..."
                accountSettings
                ;;
            2) userHome ;;
            *) accountSettings ;;
        esac
    else
        echo "[1] Delete Account"
        echo "[2] Go Back"
        echo
        read -p "Enter your choice (1-2): " choice

        case $choice in
            1) deleteAccount ;;
            2) userHome ;;
            *) accountSettings ;;
        esac
    fi
}

# Function to handle account deletion
deleteAccount() {
    clear
    echo
    echo "==================================="
    echo "        DELETE ACCOUNT"
    echo "==================================="
    echo
    echo "WARNING! This action cannot be undone!"
    echo "Your account will be scheduled for deletion"
    echo "with a cooling-off period of 3 days."
    echo
    echo "During this time, you can cancel the deletion"
    echo "by visiting Account Settings."
    echo
    echo "After 3 days, your account and all your posts"
    echo "will be permanently deleted."
    echo
    echo "Are you sure you want to proceed?"
    echo "[1] Yes, schedule my account for deletion"
    echo "[2] No, cancel and go back"
    echo
    read -p "Enter your choice (1-2): " choice

    case $choice in
        1)
            # Store today's date for deletion (Mac compatible)
            mkdir -p data/pending_deletions
            today=$(get_today)
            echo "$today" > "data/pending_deletions/$username.txt"
            
            echo
            echo "Your account has been scheduled for deletion."
            echo "It will be permanently deleted after 3 days."
            echo "You can cancel this request anytime before then."
            echo
            read -p "Press Enter to continue..."
            userHome
            ;;
        2)
            accountSettings
            ;;
        *)
            deleteAccount
            ;;
    esac
}

# Function to view profile
viewProfile() {
    clear
    echo
    echo "==================================="
    echo "        PROFILE: $username"
    echo "==================================="
    echo

    # Display profile information
    while IFS=':' read -r key value; do
        if [ "$key" != "password" ]; then
            echo "$key:$value"
        fi
    done < "data/users/$username.txt"

    echo
    echo "=== MY POSTS ==="
    echo

    postFound=0
    for file in data/posts/*.txt; do
        if [ -f "$file" ] && [ "$file" != "data/posts/*.txt" ]; then
            postUsername=$(grep "^username:" "$file" | cut -d':' -f2 | sed 's/^ //')
            postContent=$(grep "^content:" "$file" | cut -d':' -f2 | sed 's/^ //')
            postDate=$(grep "^date:" "$file" | cut -d':' -f2 | sed 's/^ //')
            postID=$(grep "^id:" "$file" | cut -d':' -f2 | sed 's/^ //')

            if [ "$postUsername" = "$username" ]; then
                postFound=1
                echo "ID: $postID"
                echo "Date: $postDate"
                echo "$postContent"
                echo "------------------------------"
            fi
        fi
    done

    if [ $postFound -eq 0 ]; then
        echo "No posts yet. Create your first post!"
    fi

    echo
    echo "[1] Go Back"
    echo
    read -p "Enter your choice: " choice

    if [ "$choice" = "1" ]; then
        userHome
    else
        viewProfile
    fi
}

# Function to create post
createPost() {
    clear
    echo
    echo "==================================="
    echo "          CREATE A POST"
    echo "==================================="
    echo
    echo "Type your post below (press Enter and type 'END' to finish):"
    echo "---------------------------------------------"
    echo

    # Read multiline input
    post=""
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        post="$post $line"
    done

    # Save post to file
    postCounter=$((postCounter + 1))
    echo "id: $postCounter" > "data/posts/post_$postCounter.txt"
    echo "username: $username" >> "data/posts/post_$postCounter.txt"
    echo "date: $(date)" >> "data/posts/post_$postCounter.txt"
    echo "content: $post" >> "data/posts/post_$postCounter.txt"

    # Update post counter
    echo $postCounter > data/postcounter.txt

    echo
    echo "Post created successfully!"
    echo
    read -p "Press Enter to continue..."
    userHome
}

# Function to view timeline
viewTimeline() {
    clear
    echo
    echo "==================================="
    echo "            TIMELINE"
    echo "==================================="
    echo

    # Check if there are any posts
    postsExist=0
    for file in data/posts/*.txt; do
        if [ -f "$file" ] && [ "$file" != "data/posts/*.txt" ]; then
            postsExist=1
            break
        fi
    done

    if [ $postsExist -eq 0 ]; then
        echo "No posts available in the timeline."
        echo
        read -p "Press Enter to continue..."
        userHome
        return
    fi

    # Display all posts sorted by newest first (using post ID as approximation)
    current=$postCounter
    
    while [ $current -gt 0 ]; do
        if [ -f "data/posts/post_$current.txt" ]; then
            postUsername=$(grep "^username:" "data/posts/post_$current.txt" | cut -d':' -f2 | sed 's/^ //')
            postContent=$(grep "^content:" "data/posts/post_$current.txt" | cut -d':' -f2 | sed 's/^ //')
            postDate=$(grep "^date:" "data/posts/post_$current.txt" | cut -d':' -f2 | sed 's/^ //')
            
            echo "===== POST #$current ====="
            echo "By: $postUsername"
            echo "Date: $postDate"
            echo "$postContent"
            echo "------------------------------"
            echo
        fi
        current=$((current - 1))
    done

    echo "[1] Refresh Timeline"
    echo "[2] Go Back"
    echo
    read -p "Enter your choice: " choice

    if [ "$choice" = "2" ]; then
        userHome
    else
        viewTimeline
    fi
}

# Function to search users
searchUsers() {
    clear
    echo
    echo "==================================="
    echo "         SEARCH FOR USERS"
    echo "==================================="
    echo
    read -p "Enter username to search: " searchTerm

    userFound=0
    for file in data/users/*.txt; do
        if [ -f "$file" ] && [ "$file" != "data/users/*.txt" ]; then
            filename=$(basename "$file" .txt)
            if [[ "$filename" == *"$searchTerm"* ]]; then
                userFound=1
                echo "Found user: $filename"
            fi
        fi
    done

    if [ $userFound -eq 0 ]; then
        echo "No users found matching '$searchTerm'"
    fi

    echo
    echo "[1] View a Profile"
    echo "[2] Go Back"
    echo
    read -p "Enter your choice: " choice

    if [ "$choice" = "1" ]; then
        read -p "Enter username to view: " viewUser
        if [ -f "data/users/$viewUser.txt" ]; then
            viewOtherProfile
        else
            echo "User does not exist!"
            read -p "Press Enter to continue..."
            searchUsers
        fi
    elif [ "$choice" = "2" ]; then
        userHome
    else
        searchUsers
    fi
}

# Function to view other user's profile
viewOtherProfile() {
    clear
    echo
    echo "==================================="
    echo "        PROFILE: $viewUser"
    echo "==================================="
    echo

    # Display profile information
    while IFS=':' read -r key value; do
        if [ "$key" != "password" ]; then
            echo "$key:$value"
        fi
    done < "data/users/$viewUser.txt"

    echo
    echo "=== POSTS ==="
    echo
    postFound=0
    for file in data/posts/*.txt; do
        if [ -f "$file" ] && [ "$file" != "data/posts/*.txt" ]; then
            postUsername=$(grep "^username:" "$file" | cut -d':' -f2 | sed 's/^ //')
            postContent=$(grep "^content:" "$file" | cut -d':' -f2 | sed 's/^ //')
            postDate=$(grep "^date:" "$file" | cut -d':' -f2 | sed 's/^ //')
            
            if [ "$postUsername" = "$viewUser" ]; then
                postFound=1
                echo "Date: $postDate"
                echo "$postContent"
                echo "------------------------------"
            fi
        fi
    done

    if [ $postFound -eq 0 ]; then
        echo "This user hasn't posted anything yet."
    fi

    echo
    echo "[1] Go Back to Search"
    echo "[2] Go Back to Home"
    echo
    read -p "Enter your choice: " choice

    if [ "$choice" = "1" ]; then
        searchUsers
    elif [ "$choice" = "2" ]; then
        userHome
    else
        viewOtherProfile
    fi
}

# Function to process all pending account deletions
processPendingDeletions() {
    echo "Checking for accounts pending deletion..."
    
    for deletionFile in data/pending_deletions/*.txt; do
        if [ -f "$deletionFile" ] && [ "$deletionFile" != "data/pending_deletions/*.txt" ]; then
            pendingUsername=$(basename "$deletionFile" .txt)
            requestDate=$(cat "$deletionFile")
            
            # Calculate days since deletion request using our Mac-compatible function
            today=$(get_today)
            daysDiff=$(calculate_days_between "$requestDate" "$today")
            
            if [ "$daysDiff" -ge 3 ]; then
                echo "Deleting account: $pendingUsername (cooling period ended)"
                
                # Delete user file
                if [ -f "data/users/$pendingUsername.txt" ]; then
                    rm "data/users/$pendingUsername.txt"
                fi
                
                # Delete all posts by this user
                for file in data/posts/*.txt; do
                    if [ -f "$file" ] && [ "$file" != "data/posts/*.txt" ]; then
                        postUsername=$(grep "^username:" "$file" | cut -d':' -f2 | sed 's/^ //')
                        if [ "$postUsername" = "$pendingUsername" ]; then
                            rm "$file"
                        fi
                    fi
                done
                
                # Remove the deletion request
                rm "$deletionFile"
            fi
        fi
    done
}

# Function for password recovery
recoverPassword() {
    clear
    echo
    echo "==================================="
    echo "        PASSWORD RECOVERY"
    echo "==================================="
    echo
    read -p "Enter your username: " username

    if [ ! -f "data/users/$username.txt" ]; then
        echo
        echo "User does not exist!"
        echo
        read -p "Press Enter to continue..."
        main
        return
    fi
    
    # Get the user's full name from their profile to verify identity
    fullname=$(grep "^fullname:" "data/users/$username.txt" | cut -d':' -f2 | sed 's/^ //')
    
    echo
    echo "For security verification, please answer the following:"
    read -p "Enter your full name exactly as it appears in your profile: " enteredName
    
    if [ "$enteredName" != "$fullname" ]; then
        echo
        echo "Verification failed. The information provided does not match our records."
        echo
        read -p "Press Enter to continue..."
        main
        return
    fi
    
    # If verification passes, allow user to set a new password
    echo
    echo "Verification successful!"
    read -p "Enter your new password: " newPassword
    
    # Update the password in the user file
    # First, get all lines except the password line
    grep -v "^password:" "data/users/$username.txt" > "data/users/temp_$username.txt"
    # Then add the new password line
    echo "password: $newPassword" >> "data/users/temp_$username.txt"
    # Replace the original file with the updated one
    mv "data/users/temp_$username.txt" "data/users/$username.txt"
    
    echo
    echo "Password has been reset successfully!"
    echo "You can now login with your new password."
    echo
    read -p "Press Enter to continue..."
    main
}

# Main application loop
main() {
    # Check for accounts pending deletion
    processPendingDeletions
    
    clear
    echo
    echo "==================================="
    echo "  SOCIALBATCH - TEXT SOCIAL MEDIA"
    echo "==================================="
    echo
    echo "[1] Login"
    echo "[2] Create New Account"
    echo "[3] Recover Password"
    echo "[4] Exit"
    echo
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1) login ;;
        2) createAccount ;;
        3) recoverPassword ;;
        4) exit 0 ;;
        *) main ;;
    esac
}

# Create pending_deletions directory if it doesn't exist
mkdir -p data/pending_deletions

# Start the application
main