#!/bin/bash

# Detects the Linux distribution by checking lsb_release, /etc/os-release, and falling back to unable to detect.
# Sets the distribution and release variables.
detect_distribution() {
  if [ -x "$(command -v lsb_release)" ]; then
    distribution=$(lsb_release -si)
    release=$(lsb_release -sr)
    echo "Detected Linux Distribution: $distribution $release"
  elif [ -f /etc/os-release ]; then
    shellcheck source=/etc/os-release
    distribution="$NAME"
    echo "Detected Linux Distribution: $NAME $VERSION"
  else
    echo "Unable to detect the Linux distribution."
  fi
}

# Function to update a Debian-based system
update_debian_system() {
  echo "Updating the system on Debian-based system..."
  apt update && apt-get upgrade -y && apt-get install sudo wget curl tar openssl bcrypt -y
  echo "The system has been updated successfully on Debian-based system."
}

# Function to update a Fedora-based system
update_fedora_system() {
  echo "Updating the system on Fedora-based system..."
  dnf update -y && dnf install sudo wget curl tar openssl bcrypt -y
  echo "The system has been updated successfully on Fedora-based system."
}

# Function to update an Arch-based system
update_arch_system() {
  echo "Updating the system on Arch-based system..."
  pacman -Syu --noconfirm && pacman -S sudo wget curl tar openssl bcrypt --noconfirm
  echo "The system has been updated successfully on Arch-based system."
}

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Detect the Linux distribution
detect_distribution

# Update the system based on the detected distribution
case "$distribution" in
  "Ubuntu" | "Debian")
    update_debian_system
    ;;
  "Fedora" | "CentOS Stream")
    update_fedora_system
    ;;
  "Arch Linux")
    update_arch_system
    ;;
  *)
    echo "System update not supported for this distribution."
    ;;
esac

######################
# Validation Section #
######################
# Validates a given username against a regex to check if it meets the required criteria.
validate_username() {
  local username=$1

  # Username regex - allows a-z, A-Z, 0-9, _, -, .
  # and minimum length of 4 characters
  if [[ $username =~ ^[a-zA-Z0-9_.]{4,}+$ ]]; then
    return 0
  else
    return 1
  fi
}

# Validates a given password against a regex to check if it meets the required criteria.
validate_password() {
  local password=$1

  # Password regex - allows a-z, A-Z, 0-9, _, -, .
  # and minimum length of 8 characters
  if [[ $password =~ ^[[:print:]]{8,}+$ ]]; then
    return 0
  else
    return 1
  fi
}

# Validates the given username against the regex criteria
# and prompts the user to retry if invalid.
# Loops continuously until a valid username is entered.
user_loop() {
  local username

while true; do
  read -r -p "Enter the username for the new user: " username
  
  if validate_username "$username"; then
    break
  else
    echo "Invalid username, please try again"
  fi
done
}

# password_loop prompts the user to enter a password and validates it against the
# validate_password function. It will continue prompting in a loop until a valid
# password is entered.
password_loop() {
  local password

while true; do
  read -r -s -p "Enter the password for $username: " password

  if validate_password "$password"; then
    break
  else
    echo "Invalid password, please try again"
  fi
done
}
#############################
# End of Validation Section #
#############################

######################
# Encryption Section #
######################

# hash generates a salt, hashes the password with bcrypt using the salt, 
# and saves the salt and hashed password to files
hash()  {
  # Generate a 16 byte random salt
  salt=$(openssl rand -base64 16)
  # Hash password with salt using bcrypt
  hashed_password=$(bcrypt "$password" "$salt" 12)
  # Save salt and hashed password
  echo "$salt" >> salts.txt
  echo "$hashed_password" >> passwords.txt
}

#############################
# End of Encryption Section #
#############################

# Function to create a user on a Debian-based system
create_debian_user() {
  # Prompt for the username and password. Validate username and password.
  user_loop
  password_loop

  # Create the user with adduser and set the password
  adduser "$username"
  echo "$username:$password" | chpasswd

  # Add the user to the 'sudo' group
  usermod -aG sudo "$username"
  echo "User $username has been added to the 'sudo' group on the Debian-based system."
}

# Function to create a user on a Fedora-based system
create_fedora_user() {
  # Prompt for the username and password
  user_loop
  password_loop

  # Create the user with useradd and set the password
  useradd "$username"
  echo "$password" | passwd --stdin "$username"

  # Add the user to the 'wheel' group (similar to 'sudo' in Fedora)
  usermod -aG wheel "$username"
  echo "User $username has been added to the 'wheel' group on the Fedora-based system."
}

# Function to create a user on an Arch-based system
create_arch_user() {
  # Prompt for the username and password
  user_loop
  password_loop

  # Create the user with useradd and set the password
  useradd -m "$username"
  echo -e "$password\n$password" | passwd "$username"

  # Add the user to the 'wheel' group (similar to 'sudo' in Arch)
  usermod -aG wheel "$username"
  echo "User $username has been created on the Arch-based system."
}

# Function to create an SSH key
create_ssh_key() {
  # Prompt for the username and remote server address
  read -r -p "Enter the remote username: " remote_username
  read -r -p "Enter the remote server address: " remote_server

  # Generate an SSH key pair with the specified filename
  key=$HOME/.ssh/id_rsa
  sudo -u "$USER" ssh-keygen -t ecdsa -b 521 -f "$key"

  # Prompt for the remote server's password (you can remove this if using key-based authentication)
  read -r -s -p "Enter the password for $remote_username@$remote_server: " password
  echo

  # Copy the public key to the remote server
  sudo -u "$USER" ssh-copy-id -i "$key.pub" "$remote_username@$remote_server"
  echo "SSH key has been copied to $remote_username@$remote_server."
}

#Change User
change_user() {
  # Prompts the user for the username
  read -r -p "Enter the username you want to switch to: " username

  # Check if a username is provided
  if [ -z "$username" ]; then
    echo "No username provided. Exiting."
    return
  fi

# Use the su command to switch to the specified user
su - "$username"
}

# Function to import a public SSH key via ssh
import_ssh_key() {
  # Prompt for the remote username and server address
  read -r -p "Enter the remote username: " remote_username
  read -r -p "Enter the remote server address: " remote_server

  # Prompt for the path to the public key file to import
  read -r -p "Enter the path to the public key file (e.g., /path/to/public_key.pub): " public_key_path

  # Prompt for the remote server's password (required for password-based authentication)
  read -r -s -p "Enter the password for $remote_username@$remote_server: " password

  # Create and append the public key from the remote server's to authorized_keys file.
  sudo -u "$USER" mkdir .ssh/
  sudo -u "$USER" ssh "$remote_username@$remote_server" "cat $public_key_path" | tee .ssh/authorized_keys
  echo "Public key has been imported successfully."
}

# Function to import a public SSH from URL
import_ssh_url() {
  # Prompt the user for the URL from where it would download the file
  read -r -p "Enter the download URL: " URL

  # Use sudo to create the .ssh directory with the correct ownership
  sudo -u "$USER" mkdir .ssh/

  # Use sudo to download the SSH key and append it to authorized_keys
  sudo -u "$USER" wget -P /tmp/ "$URL" -O - | tee -a .ssh/authorized_keys

  # Change ownership
  sudo -u "$USER" chown -R "$USER":"$USER" .ssh/
}

# Prompt the user to select one or more actions
echo "Choose one or more actions:"
echo "1. Create a user for an Ubuntu/Debian System"
echo "2. Create a user for a Fedora System"
echo "3. Create a user for an Arch System"
echo "4. Create an SSH key"
echo "5. Change User"
echo "6. Import a public SSH key via scp"
echo "7. Import public SSH key from URL"
echo "*IMPORTANT: for option 4 6 and 7 if needed change the user first, because it creates the SSH
      keys in the user folder that runs the script"
read -r -p "Enter your choice(s) (e.g., 1 2 3 4 5 6 7): " choices

# Execute the selected action(s)
for choice in $choices; do
  case $choice in
    1) create_debian_user ;;
    2) create_fedora_user ;;
    3) create_arch_user ;;
    4) create_ssh_key ;;
    5) change_user ;;
    6) import_ssh_key ;;
    7) import_ssh_url ;;
    *) echo "Invalid choice: $choice";;
  esac
done
