#!/bin/bash
ifconfig | grep ether
MAX_RETRIES=10   # Maximum number of retries
RETRY_INTERVAL=5 # Retry interval in seconds
INTERFACE="wlan0"  # Replace with your actual interface name if different

# Function to change MAC address
change_mac_address() {
    # Generate 6 pairs of random hexadecimal values
    HEX_VALUES=$(xxd -l 6 -p /dev/urandom | tr -d '\n')

    # Format the result with colons
    MAC_ADDRESS=$(echo $HEX_VALUES | sed 's/\(..\)/\1:/g; s/.$//')

    echo "Generated MAC address: $MAC_ADDRESS"

    # Bring down the interface
    ip link set dev $INTERFACE down || { echo "Failed to bring $INTERFACE down"; return 1; }

    # Set the new MAC address
    ip link set dev $INTERFACE address $MAC_ADDRESS || { echo "Failed to set MAC address"; return 1; }

    # Bring the interface back up
    ip link set dev $INTERFACE up || { echo "Failed to bring $INTERFACE up"; return 1; }

    echo "MAC address changed successfully."
    return 0
}

attempt=1
while true; do
    echo "Attempt $attempt of $MAX_RETRIES"

    # Try to change MAC address
    change_mac_address

    if [ $? -eq 0 ]; then
        echo "MAC address changed successfully."
        break
    fi

    if [ $attempt -eq $MAX_RETRIES ]; then
        echo "Error: Failed to change MAC address after $MAX_RETRIES attempts."
        exit 1
    fi

    attempt=$((attempt + 1))
    sleep $RETRY_INTERVAL
done
# Function to generate a random character
generate_random_char() {
    # Define all possible characters
    all_chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    # Use /dev/urandom to get a random number and use it as an index
    index=$(($RANDOM % ${#all_chars}))

    # Extract the character at the generated index
    rand_char=${all_chars:$index:1}

    echo $rand_char
}

# Generate a random list of 10 characters
random_list=""
for ((i=0; i<10; i++)); do
    random_list="${random_list}$(generate_random_char)"
done
random_list="Anonymous-$random_list"
old_hostname=$(cat /etc/hostname)
sha256_hash=$(echo "$random_list" | sha256sum)
sha256_hash=${sha256_hash::-2}
echo "old hostname      : $old_hostname"
echo "generated hostname: $random_list"
echo "encrypted hostname: $sha256_hash"
echo "$sha256_hash" > /etc/hostname
