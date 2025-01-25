#!/bin/bash

# This script automates basic security tasks for a Linux system.
# Note: Run this script as root or with sudo privileges.

# Update and Upgrade the System
# Ensures all installed packages are up to date.
echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y

echo "System updated successfully!"

# Remove Unnecessary or Suspicious User Accounts
# Check /etc/passwd for a list of user accounts and prompt to remove inactive accounts.
echo "Checking for unnecessary or suspicious user accounts..."
awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read user; do
    echo "Do you want to disable or delete user $user? (disable/delete/skip):"
    read choice
    case $choice in
        disable)
            sudo usermod -L $user
            echo "$user has been disabled."
            ;;
        delete)
            sudo userdel -r $user
            echo "$user has been deleted."
            ;;
        *)
            echo "$user skipped."
            ;;
    esac
done

# Secure /etc/shadow and /etc/passwd File Permissions
echo "Securing critical system file permissions..."
sudo chmod 640 /etc/shadow
sudo chmod 644 /etc/passwd
sudo chmod 644 /etc/group
sudo chmod 640 /etc/gshadow
echo "File permissions secured."

# Disable Unnecessary Services
echo "Disabling unnecessary services..."
sudo systemctl disable telnet
sudo systemctl disable cups
sudo systemctl disable nfs-server
echo "Unnecessary services have been disabled."

# Enable and Configure the UFW Firewall
echo "Configuring and enabling the firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
echo "Firewall has been configured and enabled."

# Check for World-Writable Files
echo "Checking for world-writable files and directories..."
find / -type f -perm -o+w 2>/dev/null | while read file; do
    echo "Fixing permissions for $file"
    chmod o-w "$file"
done
echo "World-writable files fixed."

# Review Cron Jobs
echo "Reviewing cron jobs..."
crontab -l > /tmp/current_crontab
if [ -s /tmp/current_crontab ]; then
    echo "User-specific cron jobs detected:"
    cat /tmp/current_crontab
else
    echo "No user-specific cron jobs found."
fi
sudo cat /etc/crontab | grep -v '^#'

# Audit Open Ports
echo "Auditing open ports..."
sudo netstat -tuln

# Secure SSH Configuration
echo "Securing SSH configuration..."
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
sudo systemctl restart ssh
echo "SSH configuration has been secured."

# Install and Run ClamAV Antivirus
echo "Installing and running ClamAV antivirus..."
sudo apt install -y clamav
sudo freshclam
sudo clamscan -r / --quiet --remove

echo "ClamAV scan completed."

# Review and Secure Log Files
echo "Securing log file permissions..."
sudo chmod 640 /var/log/*.log
echo "Log files secured."

# Summary of Actions
cat <<EOF

System Hardening Completed:
- Updated system packages
- Reviewed and managed user accounts
- Secured file permissions
- Disabled unnecessary services
- Configured UFW firewall
- Audited and fixed world-writable files
- Secured SSH
- Scanned for malware with ClamAV
- Reviewed log file permissions

EOF
