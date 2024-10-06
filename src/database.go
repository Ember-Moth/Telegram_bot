package main

import (
    "database/sql"
    "fmt"
    "log"

    _ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

// 初始化数据库连接
func initDB() {
    var err error
    dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s",
        config.Database.Username,
        config.Database.Password,
        config.Database.Host,
        config.Database.Port,
        config.Database.DBName)

    db, err = sql.Open("mysql", dsn)
    if err != nil {
        log.Fatal("连接数据库失败:", err)
    }

    // 检查数据库连接
    err = db.Ping()
    if err != nil {
        log.Fatal("数据库连接失败:", err)
    }

    // 创建用户表（如果不存在）
    createTableQuery := `
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        telegram_id BIGINT NOT NULL UNIQUE,
        uuid VARCHAR(36) NOT NULL
    );`
    _, err = db.Exec(createTableQuery)
    if err != nil {
        log.Fatal("创建表失败:", err)
    }
}

// 保存UUID到数据库
func saveUUIDToDB(telegramID int64, userUUID string) error { // 改为 int64
    var existingUUID string
    err := db.QueryRow("SELECT uuid FROM users WHERE telegram_id = ?", telegramID).Scan(&existingUUID)
    if err == sql.ErrNoRows {
        // 不存在则插入新记录
        _, err := db.Exec("INSERT INTO users (telegram_id, uuid) VALUES (?, ?)", telegramID, userUUID)
        if err != nil {
            return err
        }
    } else if err != nil {
        return err
    }

    return nil
}
