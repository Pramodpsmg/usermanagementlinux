#!/bin/sh

# Ensure script runs as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Run this script as root."
    exit 1
fi

# Function to create a new user
create_user() {
    echo -n "Enter new username: "
    read username
    if [ -z "$username" ]; then
        echo "Error: Username cannot be empty."
        return
    fi

    if id "$username" >/dev/null 2>&1; then
        echo "User '$username' already exists."
        return
    fi

    echo -n "Enter password: "
    stty -echo
    read password
    stty echo
    echo

    useradd -m -s /bin/bash "$username" && echo "$username:$password" | chpasswd
    echo "User '$username' created successfully."

    echo -n "Add user to a group? (y/n): "
    read add_group
    if [ "$add_group" = "y" ]; then
        echo -n "Enter group name: "
        read groupname
        if grep -q "^$groupname:" /etc/group; then
            usermod -aG "$groupname" "$username"
            echo "Added '$username' to group '$groupname'."
        else
            echo -n "Group '$groupname' does not exist. Create it? (y/n): "
            read create_grp
            if [ "$create_grp" = "y" ]; then
                groupadd "$groupname"
                usermod -aG "$groupname" "$username"
                echo "Group '$groupname' created and user added."
            fi
        fi
    fi
}

# Function to delete a user
delete_user() {
    echo -n "Enter username to delete: "
    read username
    if ! id "$username" >/dev/null 2>&1; then
        echo "User '$username' does not exist."
        return
    fi
    
    echo -n "Remove home directory as well? (y/n): "
    read remove_home
    if [ "$remove_home" = "y" ]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi

    echo "User '$username' deleted."
}

# List all regular users
list_users() {
    echo "System Users:"
    awk -F':' '$3 >= 1000 && $3 < 60000 { print $1 }' /etc/passwd
}

# Lock a user
lock_user() {
    echo -n "Enter username to lock: "
    read username
    if id "$username" >/dev/null 2>&1; then
        passwd -l "$username"
        echo "User '$username' locked."
    else
        echo "User '$username' does not exist."
    fi
}

# Unlock a user
unlock_user() {
    echo -n "Enter username to unlock: "
    read username
    if id "$username" >/dev/null 2>&1; then
        passwd -u "$username"
        echo "User '$username' unlocked."
    else
        echo "User '$username' does not exist."
    fi
}

# Menu display
show_menu() {
    echo ""
    echo "--------------------------------------"
    echo " Ubuntu User Management"
    echo "--------------------------------------"
    echo "1) Create a new user"
    echo "2) Delete a user"
    echo "3) List all users"
    echo "4) Lock a user"
    echo "5) Unlock a user"
    echo "6) Exit"
    echo "--------------------------------------"
}

# Main loop
while true; do
    show_menu
    echo -n "Choose an option: "
    read choice
    case "$choice" in
        1) create_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) lock_user ;;
        5) unlock_user ;;
        6) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Try again." ;;
    esac
done
