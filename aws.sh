#!/bin/bash
# AWS Lightsail Ubuntu 24.04 Startup Script
# This script will set up your instance with some common configurations and packages

# Exit immediately if a command exits with a non-zero status
set -e

# Function to generate a strong password
# Creates a 16-character password with uppercase, lowercase, numbers, and special characters
generate_strong_password() {
    # Define character sets
    UPPERCASE="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    LOWERCASE="abcdefghijklmnopqrstuvwxyz"
    NUMBERS="0123456789"
    SPECIAL="!@#$%^&*()-_=+[]{}|;:,.<>?"
    
    # Ensure at least one character from each set
    UP_CHAR=$(echo $UPPERCASE | fold -w1 | shuf | head -n1)
    LOW_CHAR=$(echo $LOWERCASE | fold -w1 | shuf | head -n1)
    NUM_CHAR=$(echo $NUMBERS | fold -w1 | shuf | head -n1)
    SPEC_CHAR=$(echo $SPECIAL | fold -w1 | shuf | head -n1)
    
    # Generate the rest randomly
    ALL_CHARS="${UPPERCASE}${LOWERCASE}${NUMBERS}${SPECIAL}"
    REST_CHARS=$(for i in {1..12}; do echo $ALL_CHARS | fold -w1 | shuf | head -n1; done | tr -d '\n')
    
    # Combine and shuffle
    COMBINED="${UP_CHAR}${LOW_CHAR}${NUM_CHAR}${SPEC_CHAR}${REST_CHARS}"
    PASSWORD=$(echo $COMBINED | fold -w1 | shuf | tr -d '\n')
    
    echo "$PASSWORD"
}

# Function to display database credentials
display_credentials() {
    # Set text colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color

    # Check if credentials file exists
    if [ ! -f /root/.credentials/db_credentials.txt ]; then
        echo "Credentials file not found."
        return 1
    fi

    # Display header
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}          DATABASE CREDENTIALS                ${NC}"
    echo -e "${GREEN}===============================================${NC}"
    echo

    # Display PostgreSQL credentials
    echo -e "${BLUE}PostgreSQL Credentials:${NC}"
    echo -e "${YELLOW}Production Database:${NC}"
    grep -A 3 "PostgreSQL Production Database:" /root/.credentials/db_credentials.txt
    echo
    echo -e "${YELLOW}Staging Database:${NC}"
    grep -A 3 "PostgreSQL Staging Database:" /root/.credentials/db_credentials.txt
    echo

    # Display MongoDB credentials
    echo -e "${BLUE}MongoDB Credentials:${NC}"
    echo -e "${YELLOW}Admin:${NC}"
    grep -A 3 "MongoDB Admin:" /root/.credentials/db_credentials.txt
    echo
    echo -e "${YELLOW}Production Database:${NC}"
    grep -A 3 "MongoDB Production Database:" /root/.credentials/db_credentials.txt
    echo
    echo -e "${YELLOW}Staging Database:${NC}"
    grep -A 3 "MongoDB Staging Database:" /root/.credentials/db_credentials.txt
    echo

    echo -e "${GREEN}===============================================${NC}"
    echo -e "${YELLOW}Important:${NC} Keep these credentials secure!"
    echo -e "${GREEN}===============================================${NC}"
}

# Create a standalone script to display credentials later
create_credentials_script() {
    cat > /usr/local/bin/show-db-credentials << 'EOF'
#!/bin/bash
# Script to display database credentials

# Set text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if credentials file exists
if [ ! -f /root/.credentials/db_credentials.txt ]; then
    echo "Credentials file not found. Has the main setup script been run?"
    exit 1
fi

# Display header
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}          DATABASE CREDENTIALS                ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo

# Display PostgreSQL credentials
echo -e "${BLUE}PostgreSQL Credentials:${NC}"
echo -e "${YELLOW}Production Database:${NC}"
grep -A 3 "PostgreSQL Production Database:" /root/.credentials/db_credentials.txt
echo
echo -e "${YELLOW}Staging Database:${NC}"
grep -A 3 "PostgreSQL Staging Database:" /root/.credentials/db_credentials.txt
echo

# Display MongoDB credentials
echo -e "${BLUE}MongoDB Credentials:${NC}"
echo -e "${YELLOW}Admin:${NC}"
grep -A 3 "MongoDB Admin:" /root/.credentials/db_credentials.txt
echo
echo -e "${YELLOW}Production Database:${NC}"
grep -A 3 "MongoDB Production Database:" /root/.credentials/db_credentials.txt
echo
echo -e "${YELLOW}Staging Database:${NC}"
grep -A 3 "MongoDB Staging Database:" /root/.credentials/db_credentials.txt
echo

echo -e "${GREEN}===============================================${NC}"
echo -e "${YELLOW}Important:${NC} Keep these credentials secure!"
echo -e "${GREEN}===============================================${NC}"
EOF

    chmod +x /usr/local/bin/show-db-credentials
    echo "Created credential display script at /usr/local/bin/show-db-credentials"
}

# Update and upgrade packages
echo "Updating and upgrading packages..."
apt-get update && apt-get upgrade -y

# Install common packages
echo "Installing common packages..."
apt-get install -y \
    build-essential \
    curl \
    git \
    htop \
    unzip \
    vim \
    wget \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    fail2ban \
    ufw \
    zip

# Configure timezone
echo "Configuring timezone to UTC..."
timedatectl set-timezone UTC

# Configure firewall
echo "Configuring firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5432/tcp  # PostgreSQL port
ufw allow 27017/tcp # MongoDB port
ufw --force enable

# Configure fail2ban
echo "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF
systemctl restart fail2ban

# Set up swap (if not already present)
if [ ! -f /swapfile ]; then
    echo "Setting up swap..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
fi

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install SDKMAN! for Java and Maven
echo "Installing SDKMAN!..."
curl -s "https://get.sdkman.io" | bash
source "/root/.sdkman/bin/sdkman-init.sh"

# Install Java 23.0.2-amzn
echo "Installing Java 23.0.2-amzn..."
sdk install java 23.0.2-amzn

# Install Maven
echo "Installing Maven..."
sdk install maven

# Setup SDKMAN! for the ubuntu user
echo "Setting up SDKMAN! for ubuntu user..."
su - ubuntu -c 'curl -s "https://get.sdkman.io" | bash'
echo 'source "/home/ubuntu/.sdkman/bin/sdkman-init.sh"' >> /home/ubuntu/.bashrc
su - ubuntu -c 'source "/home/ubuntu/.sdkman/bin/sdkman-init.sh" && sdk install java 23.0.2-amzn && sdk install maven'

# Add SDKMAN! initialization to profile
echo 'source "/root/.sdkman/bin/sdkman-init.sh"' >> /root/.bashrc
echo 'export JAVA_HOME="$HOME/.sdkman/candidates/java/current"' >> /root/.bashrc
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> /root/.bashrc

# Install PostgreSQL
echo "Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib
systemctl enable postgresql
systemctl start postgresql

# Configure PostgreSQL to listen on all interfaces (if needed)
echo "Configuring PostgreSQL..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
cat > /etc/postgresql/*/main/pg_hba.conf.additional << EOF
# Allow connections from anywhere with password authentication
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
EOF
cat /etc/postgresql/*/main/pg_hba.conf.additional >> /etc/postgresql/*/main/pg_hba.conf
systemctl restart postgresql

# Create production and staging PostgreSQL users and databases
echo "Creating production and staging PostgreSQL databases..."

# Generate strong passwords
PROD_DB_PASS=$(generate_strong_password)
STAGING_DB_PASS=$(generate_strong_password)

# Create users with secure passwords
sudo -u postgres psql -c "CREATE USER prod_user WITH PASSWORD '$PROD_DB_PASS';"
sudo -u postgres psql -c "CREATE USER staging_user WITH PASSWORD '$STAGING_DB_PASS';"

# Create databases
sudo -u postgres psql -c "CREATE DATABASE prod_db;"
sudo -u postgres psql -c "CREATE DATABASE staging_db;"

# Grant privileges
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE prod_db TO prod_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE staging_db TO staging_user;"

# Create directory for credentials
mkdir -p /root/.credentials

# Save database credentials to a secure file
cat > /root/.credentials/db_credentials.txt << EOF
PostgreSQL Production Database:
Database: prod_db
Username: prod_user
Password: $PROD_DB_PASS

PostgreSQL Staging Database:
Database: staging_db
Username: staging_user
Password: $STAGING_DB_PASS
EOF

chmod 600 /root/.credentials/db_credentials.txt

# Install MongoDB
echo "Installing MongoDB..."
apt-get install -y gnupg curl

# Import MongoDB public GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

# Create MongoDB source list file for Ubuntu
# Detect Ubuntu version and set the appropriate list
UBUNTU_VERSION=$(lsb_release -cs)

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_VERSION}/mongodb-org/8.0 multiverse" | \
   tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# Update package database
apt-get update

# Install MongoDB packages
apt-get install -y mongodb-org

# Start and enable MongoDB service
systemctl start mongod
systemctl enable mongod

# Configure MongoDB for remote access (if needed)
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
systemctl restart mongod

# Create MongoDB production and staging databases with users
echo "Creating MongoDB production and staging databases and users..."

# Generate strong MongoDB passwords
MONGO_ADMIN_PASS=$(generate_strong_password)
MONGO_PROD_PASS=$(generate_strong_password)
MONGO_STAGING_PASS=$(generate_strong_password)

# Create MongoDB admin user first
mongosh admin --eval "
  db.createUser({
    user: 'admin',
    pwd: '$MONGO_ADMIN_PASS',
    roles: [ { role: 'userAdminAnyDatabase', db: 'admin' } ]
  })
"

# Create production and staging users/databases
mongosh admin --eval "
  db = db.getSiblingDB('prod_db');
  db.createUser({
    user: 'prod_user',
    pwd: '$MONGO_PROD_PASS',
    roles: [ { role: 'readWrite', db: 'prod_db' } ]
  });
  
  db = db.getSiblingDB('staging_db');
  db.createUser({
    user: 'staging_user',
    pwd: '$MONGO_STAGING_PASS',
    roles: [ { role: 'readWrite', db: 'staging_db' } ]
  });
"

# Enable MongoDB authentication
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
systemctl restart mongod

# Save MongoDB credentials to the secure file
cat >> /root/.credentials/db_credentials.txt << EOF

MongoDB Admin:
Database: admin
Username: admin
Password: $MONGO_ADMIN_PASS

MongoDB Production Database:
Database: prod_db
Username: prod_user
Password: $MONGO_PROD_PASS

MongoDB Staging Database:
Database: staging_db
Username: staging_user
Password: $MONGO_STAGING_PASS
EOF

# Configure automatic security updates
echo "Configuring automatic security updates..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Create the credentials display script
create_credentials_script

# Clean up
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean

# Print Java and Maven versions to confirm installation
echo "Checking installed Java and Maven versions..."
source "/root/.sdkman/bin/sdkman-init.sh"
java -version
mvn -version

echo "Startup script completed!"
echo "===================================================="
echo "Java and Maven have been installed via SDKMAN!"
echo "Java version: $(source /root/.sdkman/bin/sdkman-init.sh && java -version 2>&1 | head -n 1)"
echo "Maven version: $(source /root/.sdkman/bin/sdkman-init.sh && mvn -version | head -n 1)"
echo "===================================================="
display_credentials
echo "===================================================="
echo "You can view these credentials again anytime by running: sudo show-db-credentials"
echo "===================================================="