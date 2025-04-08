# Installation Guide

## WSL Initialization Script

### Download the installer script

```bash
# Download the script
curl -o script.sh https://raw.githubusercontent.com/joshuasalcedo-dev/wsl-init.sh/refs/heads/main/script.sh
# Make it executable
chmod +x script.sh
# Run the installer
./script.sh
```

## AWS Lightsail Startup Script

If you're setting up an AWS Lightsail instance, you can use the AWS startup script from the same repository:

### Option 1: Copy and paste the script directly

You can copy the following script and paste it into your AWS Lightsail's startup script section during instance creation:

```bash
#!/bin/bash

# Create a temporary file to store the startup script
TMP_FILE=$(mktemp)

# Download the startup script from GitHub
curl -s https://raw.githubusercontent.com/joshuasalcedo-dev/wsl-init.sh/refs/heads/main/aws.sh -o $TMP_FILE

# Make the script executable
chmod +x $TMP_FILE

# Run the script and remove it afterward
$TMP_FILE && rm $TMP_FILE
```

### Option 2: Download and run directly

Alternatively, you can SSH into your AWS instance after creation and run:

```bash
curl -o aws.sh https://raw.githubusercontent.com/joshuasalcedo-dev/wsl-init.sh/refs/heads/main/aws.sh
chmod +x aws.sh
sudo ./aws.sh
```

This script will set up your AWS environment with necessary tools and configurations.
