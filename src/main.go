package main

import (
    "log"
)

func main() {
    // 加载配置
    err := loadConfig()
    if err != nil {
        log.Fatal("加载配置失败:", err)
    }

    // 初始化数据库
    initDB()
    defer db.Close()

    // 创建Telegram bot
    bot, err := createTelegramBot()
    if err != nil {
        log.Fatal(err)
    }

    // 启动bot
    bot.Start()
}
