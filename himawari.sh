# 更新系统并安装必需的软件
echo "Updating system packages and installing dependencies..."
apt install sudo -y
apt update -y && apt upgrade -y

# 配置 BBR TCP 拥塞控制
FQ="net.core.default_qdisc=fq"
BBR="net.ipv4.tcp_congestion_control=bbr"
ConfigFile="/etc/sysctl.conf"

if grep -q "net.core.default_qdisc" $ConfigFile; then
    # 如果存在但值不是fq，则替换
    sudo sed -i '/net.core.default_qdisc/c\net.core.default_qdisc=fq' $ConfigFile
else
    # 如果不存在，则添加
    echo $FQ | sudo tee -a $ConfigFile
fi

if grep -q "net.ipv4.tcp_congestion_control" $ConfigFile; then
    # 如果存在但值不是bbr，则替换
    sudo sed -i '/net.ipv4.tcp_congestion_control/c\net.ipv4.tcp_congestion_control=bbr' $ConfigFile
else
    # 如果不存在，则添加
    echo $BBR | sudo tee -a $ConfigFile
fi

# 应用更改
sudo sysctl -p

# 安装并配置防火墙（ufw）
echo "Installing UFW and configuring firewall..."
sudo apt install ufw
ufw enable

# 检查 UFW 是否启用并启动
ufw reload
ufw status

# 提示用户输入 SSH 端口号
read -p "Enter the SSH port you want to use: " ssh_port

# 确保用户输入了一个有效的端口号（1-65535）
while ! [[ "$ssh_port" =~ ^[0-9]+$ ]] || [ "$ssh_port" -lt 1 ] || [ "$ssh_port" -gt 65535 ]; do
    echo "Invalid port number. Please enter a valid port between 1 and 65535."
    read -p "Enter the SSH port you want to use: " ssh_port
done

# 允许输入的端口号通过防火墙
ufw allow "$ssh_port"

# 修改 SSH 配置文件的端口
echo "Modifying SSH port to $ssh_port..."
sed -i "s/^#Port 22/Port $ssh_port/" /etc/ssh/sshd_config

# 重启 SSH 服务
echo "Restarting SSH service..."
systemctl restart sshd

# 配置自定义 Bash 提示符和别名
echo "Configuring custom PS1 and aliases..."
echo "# Custom PS1 and Aliases" >> /etc/bash.bashrc
echo "PS1='[\e[32;40m\e[1m\u\e[32;40m\e[1m@\e[35;40m\e[1m\h\e[0m \e[34;40m\e[1m\W\e[0m]\$ '" >> /etc/bash.bashrc
echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc
echo "alias ll='ls --color=auto -l'" >> /etc/bash.bashrc
echo "alias egrep='egrep --color=auto'" >> /etc/bash.bashrc
echo "alias fgrep='fgrep --color=auto'" >> /etc/bash.bashrc
echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc

# 使 Bash 配置立即生效
source /etc/bash.bashrc

echo "All tasks completed successfully!"

# 提示用户是否需要重启机器
read -p "Do you want to reboot the system now? (y/n): " reboot_choice

if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
    echo "Rebooting the system..."
    reboot
else
    echo "Reboot skipped. Please reboot the system manually when ready."
fi
