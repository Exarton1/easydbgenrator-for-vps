#!/bin/bash
# db_setup.sh - Easy Database Setup Script
# This script helps with setting up and managing MariaDB/MySQL databases
# Made by Exarton
# Created on: April 8, 2025

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display script header
display_header() {
    clear
    echo -e "${BOLD}=========================================${NC}"
    echo -e "${BOLD}   DATABASE SETUP ASSISTANT BY Exarton   ${NC}"
    echo -e "${BOLD}=========================================${NC}"
    echo ""
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install MySQL/MariaDB
install_database() {
    display_header
    echo -e "${YELLOW}Select database system to install:${NC}"
    echo "1. MySQL"
    echo "2. MariaDB"
    echo "3. Return to main menu"
    read -p "Enter your choice (1-3): " db_choice

    case $db_choice in
        1)
            if command_exists apt; then
                echo -e "${GREEN}Installing MySQL using apt...${NC}"
                sudo apt update
                sudo apt install -y mysql-server
                sudo systemctl enable mysql
                sudo systemctl start mysql
                echo -e "${GREEN}MySQL installed successfully!${NC}"
            elif command_exists yum; then
                echo -e "${GREEN}Installing MySQL using yum...${NC}"
                sudo yum update
                sudo yum install -y mysql-server
                sudo systemctl enable mysqld
                sudo systemctl start mysqld
                echo -e "${GREEN}MySQL installed successfully!${NC}"
            else
                echo -e "${RED}Package manager not found. Please install MySQL manually.${NC}"
            fi
            ;;
        2)
            if command_exists apt; then
                echo -e "${GREEN}Installing MariaDB using apt...${NC}"
                sudo apt update
                sudo apt install -y mariadb-server
                sudo systemctl enable mariadb
                sudo systemctl start mariadb
                echo -e "${GREEN}MariaDB installed successfully!${NC}"
            elif command_exists yum; then
                echo -e "${GREEN}Installing MariaDB using yum...${NC}"
                sudo yum update
                sudo yum install -y mariadb-server
                sudo systemctl enable mariadb
                sudo systemctl start mariadb
                echo -e "${GREEN}MariaDB installed successfully!${NC}"
            else
                echo -e "${RED}Package manager not found. Please install MariaDB manually.${NC}"
            fi
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            sleep 2
            install_database
            ;;
    esac

    echo -e "${YELLOW}Would you like to run the secure installation script? (recommended)${NC}"
    echo "This will help you set root password and secure your installation."
    read -p "Run secure installation? (y/n): " secure_choice
    
    if [[ $secure_choice == "y" || $secure_choice == "Y" ]]; then
        if [[ $db_choice == 1 ]]; then
            sudo mysql_secure_installation
        else
            sudo mariadb-secure-installation
        fi
    fi
    
    read -p "Press Enter to continue..."
}

#  to create a new database
create_database() {
    display_header
    echo -e "${YELLOW}Create a new database${NC}"
    
    read -p "Enter database name: " db_name
    read -p "Enter MySQL/MariaDB root password: " -s root_pass
    echo ""
    
    # Create the database
    if mysql -u root -p"$root_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;" 2>/dev/null; then
        echo -e "${GREEN}Database '$db_name' created successfully!${NC}"
    else
        echo -e "${RED}Failed to create database. Check your root password and try again.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Ask if user wants to create a new user for this database
    echo -e "${YELLOW}Would you like to create a new user for this database?${NC}"
    read -p "Create new user? (y/n): " create_user_choice
    
    if [[ $create_user_choice == "y" || $create_user_choice == "Y" ]]; then
        read -p "Enter new username: " db_user
        read -p "Enter password for $db_user: " -s db_user_pass
        echo ""
        
        # Create user and grant privileges
        if mysql -u root -p"$root_pass" -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_user_pass';" 2>/dev/null; then
            mysql -u root -p"$root_pass" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';" 2>/dev/null
            mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;" 2>/dev/null
            echo -e "${GREEN}User '$db_user' created and granted privileges on '$db_name'!${NC}"
        else
            echo -e "${RED}Failed to create user. Check your root password and try again.${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Function to create a new database user
create_user() {
    display_header
    echo -e "${YELLOW}Create a new database user${NC}"
    
    read -p "Enter new username: " db_user
    read -p "Enter password for $db_user: " -s db_user_pass
    echo ""
    read -p "Enter MySQL/MariaDB root password: " -s root_pass
    echo ""
    
    # Create user
    if mysql -u root -p"$root_pass" -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_user_pass';" 2>/dev/null; then
        echo -e "${GREEN}User '$db_user' created successfully!${NC}"
        
        echo -e "${YELLOW}Would you like to grant privileges to this user on a database?${NC}"
        read -p "Grant privileges? (y/n): " grant_choice
        
        if [[ $grant_choice == "y" || $grant_choice == "Y" ]]; then
            read -p "Enter database name: " db_name
            
            # Grant privileges
            mysql -u root -p"$root_pass" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';" 2>/dev/null
            mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;" 2>/dev/null
            echo -e "${GREEN}Privileges granted to '$db_user' on '$db_name'!${NC}"
        fi
    else
        echo -e "${RED}Failed to create user. Check your root password and try again.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to backup a database
backup_database() {
    display_header
    echo -e "${YELLOW}Backup a database${NC}"
    
    read -p "Enter database name to backup: " db_name
    read -p "Enter MySQL/MariaDB root password: " -s root_pass
    echo ""
    
    # Create backup directory if it doesn't exist
    backup_dir="./db_backups"
    mkdir -p "$backup_dir"
    
    # Create backup filename with timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_file="$backup_dir/${db_name}_${timestamp}.sql"
    
    # Perform backup
    if mysqldump -u root -p"$root_pass" "$db_name" > "$backup_file" 2>/dev/null; then
        echo -e "${GREEN}Database '$db_name' backed up successfully to '$backup_file'!${NC}"
    else
        echo -e "${RED}Failed to backup database. Check your root password and database name.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to restore a database
restore_database() {
    display_header
    echo -e "${YELLOW}Restore a database${NC}"
    
    # List available backups
    backup_dir="./db_backups"
    if [ ! -d "$backup_dir" ] || [ -z "$(ls -A "$backup_dir")" ]; then
        echo -e "${RED}No backups found in '$backup_dir'.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}Available backups:${NC}"
    ls -1 "$backup_dir" | cat -n
    
    read -p "Enter the number of the backup to restore: " backup_num
    backup_file=$(ls -1 "$backup_dir" | sed -n "${backup_num}p")
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}Invalid selection.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Enter the database name to restore to: " db_name
    read -p "Enter MySQL/MariaDB root password: " -s root_pass
    echo ""
    
    # Check if database exists, create if not
    mysql -u root -p"$root_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;" 2>/dev/null
    
    # Restore backup
    if mysql -u root -p"$root_pass" "$db_name" < "$backup_dir/$backup_file" 2>/dev/null; then
        echo -e "${GREEN}Database restored successfully from '$backup_file' to '$db_name'!${NC}"
    else
        echo -e "${RED}Failed to restore database. Check your root password and try again.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to display database status
check_status() {
    display_header
    echo -e "${YELLOW}Database Server Status${NC}"
    
    # Check if MySQL/MariaDB is installed
    if command_exists mysql; then
        echo -e "${GREEN}MySQL/MariaDB client is installed.${NC}"
        
        # Check if server is running
        if command_exists systemctl; then
            if systemctl is-active --quiet mysql; then
                echo -e "${GREEN}MySQL server is running.${NC}"
            elif systemctl is-active --quiet mariadb; then
                echo -e "${GREEN}MariaDB server is running.${NC}"
            else
                echo -e "${RED}Database server is not running.${NC}"
            fi
        else
            echo -e "${YELLOW}Cannot determine server status (systemctl not found).${NC}"
        fi
        
        # Try to get version info
        echo -e "${YELLOW}Version information:${NC}"
        mysql --version
    else
        echo -e "${RED}MySQL/MariaDB is not installed.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Main menu function
main_menu() {
    while true; do
        display_header
        echo -e "${YELLOW}What would you like to do?${NC}"
        echo "1. Install MySQL/MariaDB"
        echo "2. Create a new database"
        echo "3. Create a new database user"
        echo "4. Backup a database"
        echo "5. Restore a database"
        echo "6. Check database server status"
        echo "7. Exit"
        
        read -p "Enter your choice (1-7): " choice
        
        case $choice in
            1) install_database ;;
            2) create_database ;;
            3) create_user ;;
            4) backup_database ;;
            5) restore_database ;;
            6) check_status ;;
            7) 
                echo -e "${GREEN}Thank you for using the Database Setup Assistant by Exarton!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Start the script
main_menu
