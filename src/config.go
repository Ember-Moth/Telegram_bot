package main

import (
    "encoding/json"
    "io/ioutil"
    "os"
)

// Config 用于存储配置信息
type Config struct {
    BotToken string   `json:"botToken"`
    Database Database `json:"database"`
    XrayAPIs []string `json:"xrayAPIs"`
}

// Database 用于数据库配置信息
type Database struct {
    Username string `json:"username"`
    Password string `json:"password"`
    Host     string `json:"host"`
    Port     int    `json:"port"`
    DBName   string `json:"dbname"`
}

var config Config

// 加载配置文件
func loadConfig() error {
    file, err := os.Open("/etc/bot/config.json")
    if err != nil {
        return err
    }
    defer file.Close()

    bytes, err := ioutil.ReadAll(file)
    if err != nil {
        return err
    }

    err = json.Unmarshal(bytes, &config)
    if err != nil {
        return err
    }

    return nil
}
