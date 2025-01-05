#!/bin/bash
#Author Chamil Bandara

set -e
echo "Changing SELINUX to permissive"
sed -i 's\SELINUX=enforcing\SELINUX=permissive\g'  /etc/selinux/config

echo "Updating package repository..."
sudo dnf update -y

echo "Installing podman and dependencies..."
sudo dnf install -y podman podman-compose

echo "Create MySQL and Grafana users"
sudo useradd -r -s /sbin/nologin mysql
sudo useradd -r -s /sbin/nologin grafana


echo "Creating required directories for MySQL and Grafana..."

sudo mkdir -p /var/lib/mysql_data
sudo mkdir -p /var/lib/grafana_data

echo "Changing host directory permissions for mount volums"
sudo chown -R mysql:mysql /var/lib/mysql_data
sudo chown -R grafana:grafana /var/lib/grafana_data
sudo chmod -R 755 /var/lib/grafana_data
sudo chmod -R 755 /var/lib/mysql_data

echo "Creating project folder"

sudo mkdir -p /project/mysql_data
sudo mkdir -p /project/grafana_data


echo "Changing to project directory..."
cd /project

echo "Changing project folder permissions"
sudo chown -R grafana:grafana grafana_data
sudo chmod -R 755 grafana_data
sudo chown -R mysql:mysql mysql_data
sudo chmod -R 755 mysql_data

echo "Creating backup folder to project content"
sudo mkdir -p /autostart/mysql_data
sudo mkdir -p /autostart/grafana_data
sudo chown -R grafana:grafana /autostart/grafana_data
sudo chmod -R 755 /autostart/grafana_data
sudo chown -R mysql:mysql /autostart/mysql_data
sudo chmod -R 755 /autostart/mysql_data

echo "Copy content to backup folder"
sudo cp -rv /project/* /autostart/


echo "Deploying services with podman Compose..."
sudo podman-compose up -d

# Gather system and service details
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $2}')
MYSQL_CONTAINER=$(podman ps --filter "name=mysql" --format "{{.Names}}")
MYSQL_STATUS=$(podman inspect $MYSQL_CONTAINER --format "{{.State.Status}}")
MYSQL_PORT=3306
MYSQL_USER="grafana"
MYSQL_PASSWORD="grafana"
GRAFANA_URL="http://$IP_ADDRESS:3000"
PHPMYADMI_URL="http://$IP_ADDRESS:8080"

echo "Creting startup configurations"
sudo podman generate systemd --name mysql --new > /etc/systemd/system/container-mysql.service
sudo podman generate systemd --name phpmyadmin --new > /etc/systemd/system/container-phpmyadmin.service
sudo podman generate systemd --name grafana --new > /etc/systemd/system/container-grafana.service
sudo systemctl enable container-mysql.service
systemctl enable container-grafana.service
systemctl enable container-phpmyadmin.service


# Output installation details
echo -e "\n====== Installation Summary ======"
echo "Hostname: $HOSTNAME"
echo "IP Address: $IP_ADDRESS"
echo "MySQL Server:"
echo "  - Container Name: $MYSQL_CONTAINER"
echo "  - Status: $MYSQL_STATUS"
echo "  - Port: $MYSQL_PORT"
echo "  - Username: $MYSQL_USER"
echo "  - Password: $MYSQL_PASSWORD"
echo "Grafana Dashboard:"
echo "  - URL: $GRAFANA_URL"
echo " Phpmyadmin Portal: "
echo "  - URL: $PHPMYADMI_URL"
echo "=================================="
