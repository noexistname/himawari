# 更新系统并安装必需的软件
echo "Updating system packages and installing dependencies..."
apt-get install wget sudo vim git -y
sudo apt-get update -y && sudo apt upgrade -y

# 配置自定义 Bash 提示符和别名
echo "Configuring custom PS1 and aliases..."
echo "PS1='[\e[32;40m\e[1m\u\e[32;40m\e[1m@\e[35;40m\e[1m\h\e[0m \e[34;40m\e[1m\W\e[0m]\$ '" >> /etc/bash.bashrc
echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc
echo "alias ll='ls --color=auto -l'" >> /etc/bash.bashrc
echo "alias egrep='egrep --color=auto'" >> /etc/bash.bashrc
echo "alias fgrep='fgrep --color=auto'" >> /etc/bash.bashrc
echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc

# 使 Bash 配置立即生效
source /etc/bash.bashrc

# 配置 BBR TCP 拥塞控制
echo "Configuring BBR TCP Congestion Control..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sudo sysctl -p

# 安装并配置防火墙（ufw）
echo "Installing UFW and configuring firewall..."
sudo apt-get install -y ufw
sudo ufw enable -y

# 提示用户输入 SSH 端口号
read -p "Enter the SSH port you want to use: " ssh_port

# 确保用户输入了一个有效的端口号（1-65535）
while ! [[ "$ssh_port" =~ ^[0-9]+$ ]] || [ "$ssh_port" -lt 1 ] || [ "$ssh_port" -gt 65535 ]; do
    echo "Invalid port number. Please enter a valid port between 1 and 65535."
    read -p "Enter the SSH port you want to use: " ssh_port
done

# 允许输入的端口号通过防火墙
sudo ufw allow "$ssh_port"

# 修改 SSH 配置文件的端口
echo "Modifying SSH port to $ssh_port..."
sudo sed -i "s/^#Port 22/Port $ssh_port/" /etc/ssh/sshd_config

# 重启 SSH 服务
echo "Restarting SSH service..."
sudo systemctl restart sshd

echo "All tasks completed successfully!"

# 提示用户是否需要重启机器
read -p "Do you want to reboot the system now? (y/n): " reboot_choice

if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
    echo "Rebooting the system..."
    reboot
else
    echo "Reboot skipped. Please reboot the system manually when ready."
fi
