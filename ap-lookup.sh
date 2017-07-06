#!/bin/bash
#
# Julio 2017 rpi 3 jessie image, Lookup
#


apt-get update

if [ "$EUID" -ne 0 ]
	then echo "Must be root"
	exit
fi

if [[ $# -lt 1 ]];
	then echo "Ingresar Password para el AP (8 dígitos o más)"
	echo "Usage:"
	echo "sudo $0 yourChosenPassword [apName]"
	exit
fi

APPASS="$1"
APSSID="rPi3"

if [[ $# -eq 2 ]]; then
	APSSID=$2
fi

apt-get install dnsmasq hostapd

echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

sed -i -- 's/iface eth0 inet manual//g' /etc/network/interfaces

cat >> /etc/network/interfaces <<EOF
iface eth0 inet static
address 192.168.1.32
netmask 255.255.255.0
network 192.168.1.0
broadcast 192.168.1.255
gateway 192.168.1.254
EOF

sed -i -- 's/allow-hotplug wlan0//g' /etc/network/interfaces
sed -i -- 's/iface wlan0 inet manual//g' /etc/network/interfaces
sed -i -- 's/    wpa-conf \/etc\/wpa_supplicant\/wpa_supplicant.conf//g' /etc/network/interfaces

cat >> /etc/network/interfaces <<EOF
	wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
# Added by rPi Access Point Setup
allow-hotplug wlan0
iface wlan0 inet static
	address 10.0.0.1
	netmask 255.255.255.0
	network 10.0.0.0
	broadcast 10.0.0.255
EOF

sudo service dhcpcd restart
sudo ifdown wlan0; sudo ifup wlan0



cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
hw_mode=g
channel=10
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
wpa_passphrase=$APPASS
ssid=$APSSID
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
ignore_broadcast_ssid=0
EOF



sed -i -- 's/#DAEMON_CONF=""//g' /etc/default/hostapd
echo "DAEMON_CONF="/etc/hostapd/hostapd.conf"" >> /etc/default/hostapd

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig


cat > /etc/dnsmasq.conf <<EOF
interface=wlan0      # Use interface wlan0
listen-address=10.0.0.1 # Explicitly specify the address to listen on
bind-interfaces      # Bind to the interface to make sure we aren't sending things elsewhere
server=8.8.8.8       # Forward DNS requests to Google DNS
domain-needed        # Don't forward short names
bogus-priv           # Never forward addresses in the non-routed address spaces.
dhcp-range=10.0.0.2,10.0.0.100,255.255.255.0,12h # Assign IP addresses between 172.24.1.50 and 172.24.1.150 with a 12 hour lease time
EOF

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sh -c "iptables-save > /etc/iptables.ipv4.nat"
sed -i -- 's/exit 0//g' /etc/rc.local
echo "iptables-restore < /etc/iptables.ipv4.nat" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

sudo service hostapd start
sudo service dnsmasq start

echo "Listo!!! :D"
reboot
