package main

import (
    "crypto/sha1"
    "encoding/hex"
    "fmt"
    "log"
    "time"

    "gopkg.in/tucnak/telebot.v2"
)

// 生成基于Telegram ID的UUID
func generateUUIDFromTelegramID(telegramID int64) string {
    hash := sha1.New()
    hash.Write([]byte(fmt.Sprint(telegramID)))
    uuid := hex.EncodeToString(hash.Sum(nil))[:36] // 36位UUID
    return uuid
}

// 创建Telegram bot
func createTelegramBot() (*telebot.Bot, error) {
    bot, err := telebot.NewBot(telebot.Settings{
        Token:  config.BotToken,
        Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
    })
    if err != nil {
        return nil, err
    }

    // 处理 /uuid 命令
    bot.Handle("/uuid", func(m *telebot.Message) {
        handleUUIDCommand(bot, m)
    })

    return bot, nil
}

// 处理 /uuid 命令
func handleUUIDCommand(b *telebot.Bot, m *telebot.Message) {
    telegramID := m.Sender.ID // telegramID 现在是 int64
    userUUID := generateUUIDFromTelegramID(telegramID)

    // 保存UUID到数据库
    err := saveUUIDToDB(telegramID, userUUID) // 传入 int64
    if err != nil {
        b.Send(m.Sender, "保存 UUID 失败，请稍后再试。")
        log.Println("数据库错误:", err)
        return
    }

    // 构造用户邮箱
    email := fmt.Sprintf("user_%d@example.com", telegramID)

    // 向所有 Xray API 发送用户信息
    for _, xrayAPI := range config.XrayAPIs {
        go func(api string) {
            err := addUserToXray(userUUID, email, api)
            if err != nil {
                log.Printf("向 Xray API %s 添加用户失败: %v", api, err)
            }
        }(xrayAPI)
    }

    // 成功后返回给用户
    b.Send(m.Sender, fmt.Sprintf("您的 UUID: %s 已发送到 Xray 节点。", userUUID))
}
