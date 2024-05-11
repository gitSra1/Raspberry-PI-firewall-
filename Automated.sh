#!/bin/bash

# Install necessary packages
sudo apt update
sudo apt install -y hostapd dnsmasq

# Stop existing services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Configure hostapd (Wi-Fi Access Point)
sudo bash -c 'cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=YourNetworkName  # Replace with your desired SSID
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=YourWiFiPassword  # Replace with your desired password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF'

# Configure dnsmasq (DHCP and DNS)
sudo bash -c 'cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=10.3.141.2,10.3.141.20,255.255.255.0,24h
EOF'

# Enable IP forwarding
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'

# Configure NAT (if necessary)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

# Save iptables rules
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Make IP forwarding and iptables rules persistent
sudo bash -c 'cat > /etc/rc.local <<EOF
#!/bin/sh -e
iptables-restore < /etc/iptables.ipv4.nat
echo 1 > /proc/sys/net/ipv4/ip_forward
exit 0
EOF'

sudo chmod +x /etc/rc.local

# Start services
sudo systemctl start hostapd
sudo systemctl start dnsmasq

echo "Wi-Fi access point configured. Connect to 'YourNetworkName' with 'YourWiFiPassword'."
