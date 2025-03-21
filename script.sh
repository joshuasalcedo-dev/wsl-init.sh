#!/bin/bash

# SWA Development Environment Installer
# Created: March 12, 2025

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define the banner
BANNER=$(cat << 'EOF'
   _______          **      **_____          __         
  / ____\ \        / /\    / ____\ \        / /\        
 | (___  \ \  /\  / /  \  | (___  \ \  /\  / /  \       
  \___ \  \ \/  \/ / /\ \  \___ \  \ \/  \/ / /\ \      
  ____) |  \  /\  / ____ \ ____) |  \  /\  / ____ \     
 |_____/ ___\/__\/_/   *\*\_____/ ___\/_ \/_/___ \_\  __
 |  ** \|  **__\ \    / /        |  ____| \ | \ \    / /
 | |  | | |__   \ \  / /   ______| |__  |  \| |\ \  / / 
 | |  | |  **|   \ \/ /   |**____|  __| | . ` | \ \/ /  
 | |__| | |____   \  /           | |____| |\  |  \  /   
 |_____/|______|   \/            |______|_| \_|   \/    
EOF
)

# Print banner
echo -e "${BLUE}$BANNER${NC}"
echo -e "${BLUE}SWA Development Environment Installer${NC}"
echo -e "${YELLOW}This script will install and configure your development environment.${NC}"
echo

# Ask for Git configuration
read -p "Enter your Git name [Joshua Salcedo]: " GIT_NAME
GIT_NAME=${GIT_NAME:-"joshuasalcedo-dev"}

read -p "Enter your Git email [joshua.salcedo@chatters.chat]: " GIT_EMAIL
GIT_EMAIL=${GIT_EMAIL:-"dev@joshuasalcedo.io"}

# Ask for components to install
echo
echo "Select components to install:"
echo "1. All components (recommended)"
echo "2. Custom selection"
read -p "Enter choice [1]: " COMPONENT_CHOICE
COMPONENT_CHOICE=${COMPONENT_CHOICE:-1}

if [ "$COMPONENT_CHOICE" -eq 2 ]; then
    read -p "Install system updates? (y/n) [y]: " INSTALL_SYSTEM
    INSTALL_SYSTEM=${INSTALL_SYSTEM:-y}
    
    read -p "Install Java and SDKMAN? (y/n) [y]: " INSTALL_JAVA
    INSTALL_JAVA=${INSTALL_JAVA:-y}
    
    read -p "Install Maven? (y/n) [y]: " INSTALL_MAVEN
    INSTALL_MAVEN=${INSTALL_MAVEN:-y}
    
    read -p "Install Node.js? (y/n) [y]: " INSTALL_NODE
    INSTALL_NODE=${INSTALL_NODE:-y}
    
    read -p "Install Python? (y/n) [y]: " INSTALL_PYTHON
    INSTALL_PYTHON=${INSTALL_PYTHON:-y}
    
    read -p "Install Rust? (y/n) [y]: " INSTALL_RUST
    INSTALL_RUST=${INSTALL_RUST:-y}
    
    read -p "Install PostgreSQL and H2? (y/n) [y]: " INSTALL_POSTGRES
    INSTALL_POSTGRES=${INSTALL_POSTGRES:-y}
    
    read -p "Install MongoDB? (y/n) [y]: " INSTALL_MONGODB
    INSTALL_MONGODB=${INSTALL_MONGODB:-y}
    
    read -p "Install Redis? (y/n) [y]: " INSTALL_REDIS
    INSTALL_REDIS=${INSTALL_REDIS:-y}
    
    read -p "Configure Git? (y/n) [y]: " CONFIGURE_GIT
    CONFIGURE_GIT=${CONFIGURE_GIT:-y}
    
    read -p "Generate SSH key? (y/n) [y]: " GENERATE_SSH
    GENERATE_SSH=${GENERATE_SSH:-y}
else
    INSTALL_SYSTEM=y
    INSTALL_JAVA=y
    INSTALL_MAVEN=y
    INSTALL_NODE=y
    INSTALL_PYTHON=y
    INSTALL_RUST=y
    INSTALL_POSTGRES=y
    INSTALL_MONGODB=y
    INSTALL_REDIS=y
    CONFIGURE_GIT=y
    GENERATE_SSH=y
fi

# Confirm installation
echo
echo -e "${YELLOW}Ready to install the following components:${NC}"
[ "$INSTALL_SYSTEM" = "y" ] && echo "- System updates"
[ "$INSTALL_JAVA" = "y" ] && echo "- Java 17 (via SDKMAN)"
[ "$INSTALL_MAVEN" = "y" ] && echo "- Maven"
[ "$INSTALL_NODE" = "y" ] && echo "- Node.js (LTS)"
[ "$INSTALL_PYTHON" = "y" ] && echo "- Python"
[ "$INSTALL_RUST" = "y" ] && echo "- Rust"
[ "$INSTALL_POSTGRES" = "y" ] && echo "- PostgreSQL and H2"
[ "$INSTALL_MONGODB" = "y" ] && echo "- MongoDB"
[ "$INSTALL_REDIS" = "y" ] && echo "- Redis"
[ "$CONFIGURE_GIT" = "y" ] && echo "- Git configuration for: $GIT_NAME <$GIT_EMAIL>"
[ "$GENERATE_SSH" = "y" ] && echo "- SSH key generation"

echo
read -p "Proceed with installation? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [ "$CONFIRM" != "y" ]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

echo -e "\n${GREEN}Starting installation...${NC}\n"

# Update and upgrade the system
if [ "$INSTALL_SYSTEM" = "y" ]; then
    echo -e "${BLUE}Updating system packages...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y tree zip curl wget
    echo -e "${GREEN}System updates completed.${NC}\n"
fi

# Install SDKMAN and Java
if [ "$INSTALL_JAVA" = "y" ]; then
    echo -e "${BLUE}Installing SDKMAN and Java 17...${NC}"
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
    sdk install java 17.0.14-amzn
    sdk install java 23.0.2-graal
    sdk install java 21.0.6-amzn 
    sdk install 
    echo -e "${GREEN}Java 17 installation completed.${NC}\n"
fi

# Install Spring CLI
if [ "$INSTALL_JAVA" = "y" ]; then
    echo -e "${BLUE}Installing Spring CLI...${NC}"
    
    # Set JAVA_HOME to the GraalVM installation for best compatibility
    JAVA_HOME=$(sdk home java 17.0.14-amzn)
    export JAVA_HOME
    export PATH=$JAVA_HOME/bin:$PATH
    
    # Create a temporary directory for Spring CLI source
    SPRING_CLI_DIR="$HOME/.temp/spring-cli"
    mkdir -p "$SPRING_CLI_DIR"
    
    # Clone the Spring CLI repository
    git clone https://github.com/spring-projects/spring-cli "$SPRING_CLI_DIR"
    
    # Build Spring CLI
    cd "$SPRING_CLI_DIR"
    ./gradlew clean build -x test
    
    # Create alias for Spring CLI in .bashrc
    SPRING_ALIAS="alias spring='java -jar $SPRING_CLI_DIR/build/libs/spring-cli-0.10.0.jar'"
    
    if ! grep -q "alias spring=" "$HOME/.bashrc"; then
        echo "$SPRING_ALIAS" >> "$HOME/.bashrc"
    fi
    
    echo -e "${GREEN}Spring CLI installation completed.${NC}"
    echo -e "${YELLOW}Use 'spring' command after restarting your terminal or run 'source ~/.bashrc'${NC}\n"
fi




# Install Maven
if [ "$INSTALL_MAVEN" = "y" ]; then
    echo -e "${BLUE}Installing Maven...${NC}"
    sudo apt install -y maven
    echo -e "${GREEN}Maven installation completed.${NC}\n"
fi

# Install Node.js
if [ "$INSTALL_NODE" = "y" ]; then
    echo -e "${BLUE}Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    echo -e "${GREEN}Node.js installation completed.${NC}\n"
fi

# Install Python
if [ "$INSTALL_PYTHON" = "y" ]; then
    echo -e "${BLUE}Installing Python...${NC}"
    sudo apt install -y python3 python3-pip python3-venv
    echo -e "${GREEN}Python installation completed.${NC}\n"
fi

# Install Rust
if [ "$INSTALL_RUST" = "y" ]; then
    echo -e "${BLUE}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo -e "${GREEN}Rust installation completed.${NC}\n"
fi

# Install PostgreSQL
if [ "$INSTALL_POSTGRES" = "y" ]; then
    echo -e "${BLUE}Installing PostgreSQL...${NC}"
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    echo -e "${BLUE}Installing H2 Database...${NC}"
    H2_JAR_PATH="/usr/local/bin/h2.jar"
    if [ ! -f "$H2_JAR_PATH" ]; then
        sudo wget -O "$H2_JAR_PATH" https://h2database.com/h2-2023-07-09.zip
        sudo chmod +x "$H2_JAR_PATH"
    fi
    echo -e "${GREEN}PostgreSQL and H2 installation completed.${NC}\n"
fi

# Install MongoDB
if [ "$INSTALL_MONGODB" = "y" ]; then
    echo -e "${BLUE}Installing MongoDB...${NC}"
    sudo apt install -y mongodb
    sudo systemctl enable mongodb
    sudo systemctl start mongodb
    echo -e "${GREEN}MongoDB installation completed.${NC}\n"
fi

# Install Redis
if [ "$INSTALL_REDIS" = "y" ]; then
    echo -e "${BLUE}Installing Redis...${NC}"
    sudo apt install -y redis-server
    sudo systemctl enable redis
    sudo systemctl start redis
    echo -e "${GREEN}Redis installation completed.${NC}\n"
fi

# Configure Git
if [ "$CONFIGURE_GIT" = "y" ]; then
    echo -e "${BLUE}Configuring Git...${NC}"
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.editor "nano"
    echo -e "${GREEN}Git configuration completed.${NC}\n"
fi

# Generate SSH Key
if [ "$GENERATE_SSH" = "y" ]; then
    echo -e "${BLUE}Generating SSH Key...${NC}"
    SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    if [ ! -f "$SSH_KEY_PATH" ]; then
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t rsa -b 4096 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
    fi
    
    # Display SSH Public Key
    echo -e "\n${YELLOW}=== COPY THIS SSH KEY TO GITHUB ===${NC}\n"
    cat "$SSH_KEY_PATH.pub"
    echo -e "\n${YELLOW}====================================${NC}\n"
fi

# Store the banner in a file for reuse
echo "$BANNER" > "$HOME/.banner"

# Modify ~/.bashrc to show the banner after `clear`
BASHRC_UPDATE='
# Show the banner after clear command
clear() {
    command clear
    cat ~/.banner
}'

if ! grep -q "Show the banner after clear command" "$HOME/.bashrc"; then
    echo "$BASHRC_UPDATE" >> "$HOME/.bashrc"
fi

# Print Installed Software Versions
echo -e "\n${YELLOW}=== Installed Software Versions ===${NC}"
[ "$INSTALL_NODE" = "y" ] && echo -e "Node.js: $(node -v)"
[ "$INSTALL_NODE" = "y" ] && echo -e "NPM: $(npm -v)"
[ "$INSTALL_PYTHON" = "y" ] && echo -e "Python: $(python3 --version)"
[ "$INSTALL_RUST" = "y" ] && echo -e "Rust: $(rustc --version)"
[ "$INSTALL_JAVA" = "y" ] && echo -e "Java: $(java -version 2>&1 | head -n 1)"
[ "$INSTALL_MAVEN" = "y" ] && echo -e "Maven: $(mvn -version | head -n 1)"
[ "$INSTALL_POSTGRES" = "y" ] && echo -e "PostgreSQL: $(psql --version)"
[ "$INSTALL_MONGODB" = "y" ] && echo -e "MongoDB: $(mongod --version | head -n 1)"
[ "$INSTALL_REDIS" = "y" ] && echo -e "Redis: $(redis-server --version | awk '{print $1, $2}')"
[ "$CONFIGURE_GIT" = "y" ] && echo -e "Git: $(git --version)"
echo -e "${YELLOW}===============================${NC}\n"

echo -e "${GREEN}Installation complete! 🚀${NC}"
echo -e "Type '${YELLOW}clear${NC}' or restart your terminal to see your new banner!\n"
