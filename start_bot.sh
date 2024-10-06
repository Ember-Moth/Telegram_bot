#!/bin/bash

# 将当前目录添加到 PATH
export PATH=$PATH:$(pwd)

# 定义变量
PROJECT_NAME="dashboard_bot"
SRC_DIR="./src"  # 源代码目录
BIN_DIR="/usr/local/bin"  # 安装目录
SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"  # systemd 服务文件
LOG_FILE="/var/log/$PROJECT_NAME.log"  # 日志文件
CONFIG_FILE="/etc/bot/config.json"  # 配置文件

# 检查 Go 是否安装
function check_go_installed {
    if ! command -v go &> /dev/null; then
        echo "Go 未安装，正在安装 Go..."
        sudo apt update
        sudo apt install -y golang  # 使用 apt 安装 Go
        if [[ $? -ne 0 ]]; then
            echo "Go 安装失败，请手动安装 Go。"
            exit 1
        fi
        echo "Go 安装成功！"
    else
        echo "Go 已安装：$(go version)"
    fi
}

# 检测程序是否已安装
function check_installed {
    if [[ -f "$BIN_DIR/$PROJECT_NAME" ]]; then
        echo "$PROJECT_NAME 已安装。"
        return 0
    else
        echo "$PROJECT_NAME 未安装。"
        return 1
    fi
}

# 移动配置文件
function move_config {
    echo "正在移动配置文件 $CONFIG_FILE..."
    sudo mkdir -p /etc/bot  # 确保目录存在
    sudo mv ./config/config.json $CONFIG_FILE
    if [[ $? -eq 0 ]]; then
        echo "配置文件 $CONFIG_FILE 移动成功！"
    else
        echo "配置文件移动失败，请检查文件路径。"
        exit 1
    fi
}

# 安装缺少的依赖
function install_dependencies {
    if [ -f "$SRC_DIR/go.mod" ]; then
        echo "检测到 go.mod 文件，正在安装缺少的依赖..."
        cd "$SRC_DIR" || exit
        go mod tidy
        if [[ $? -ne 0 ]]; then
            echo "依赖安装失败，请检查 go.mod 文件。"
            exit 1
        fi
        echo "依赖安装成功！"
        cd - || exit
    else
        echo "未找到 go.mod 文件，跳过依赖安装。"
    fi
}

# 创建服务文件
function create_service {
    echo "正在创建服务文件 $SERVICE_FILE..."
    cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=Dashboard Bot Service
After=network.target

[Service]
Type=simple
ExecStart=$BIN_DIR/$PROJECT_NAME -config $CONFIG_FILE
Restart=on-failure
User=nobody
Group=nogroup
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOL
    echo "服务文件 $SERVICE_FILE 创建成功！"
}

# 编译程序
function build_project {
    echo "正在编译 $PROJECT_NAME..."
    install_dependencies  # 在编译之前安装依赖
    go build -o "$BIN_DIR/$PROJECT_NAME" "$SRC_DIR/main.go"
    if [[ $? -ne 0 ]]; then
        echo "编译失败，请检查源代码。"
        exit 1
    fi
    echo "$PROJECT_NAME 编译成功！"
}

# 安装程序
function install {
    check_installed
    if [[ $? -eq 0 ]]; then
        echo "程序已安装，无法重复安装。"
        exit 0
    fi

    # 检查 Go 是否已安装
    check_go_installed

    move_config
    build_project
    create_service

    # 重新加载systemd配置
    sudo systemctl daemon-reload
    # 启动服务
    sudo systemctl start $PROJECT_NAME
    # 设置开机自启动
    sudo systemctl enable $PROJECT_NAME
    echo "$PROJECT_NAME 安装完成并已启动！"
}

# 卸载程序
function uninstall {
    echo "正在卸载 $PROJECT_NAME..."
    sudo systemctl stop $PROJECT_NAME
    sudo systemctl disable $PROJECT_NAME
    sudo rm -f $SERVICE_FILE
    sudo rm -f "$BIN_DIR/$PROJECT_NAME"
    sudo rm -f $CONFIG_FILE
    echo "$PROJECT_NAME 卸载完成！"
}

# 修改配置文件
function edit_config {
    echo "正在使用 vim 编辑配置文件 $CONFIG_FILE..."
    sudo vim $CONFIG_FILE
}

# 查看服务状态
function check_status {
    echo "正在查看 $PROJECT_NAME 的运行状态..."
    sudo systemctl status $PROJECT_NAME
}

# 查看运行日志
function view_logs {
    echo "正在查看 $PROJECT_NAME 的运行日志..."
    sudo journalctl -u $PROJECT_NAME -f
}

# 主菜单
function main_menu {
    while true; do
        echo ""
        echo "请选择操作："
        echo "1. 安装"
        echo "2. 卸载"
        echo "3. 暂停"
        echo "4. 重启"
        echo "5. 修改配置"
        echo "6. 查看运行状态"
        echo "7. 查看运行日志"
        echo "8. 退出"
        read -p "请输入选项 (1-8): " choice

        case $choice in
            1) install ;;
            2) uninstall ;;
            3) sudo systemctl stop $PROJECT_NAME; echo "$PROJECT_NAME 已暂停。" ;;
            4) sudo systemctl restart $PROJECT_NAME; echo "$PROJECT_NAME 已重启。" ;;
            5) edit_config ;;  # 直接调用 vim 编辑配置文件
            6) check_status ;;  # 查看运行状态
            7) view_logs ;;  # 查看运行日志
            8) echo "退出脚本。"; exit ;;
            *) echo "无效选项，请重试。" ;;
        esac
    done
}

# 运行主菜单
main_menu
