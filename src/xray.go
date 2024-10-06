package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
)

// 通过Xray API添加用户
func addUserToXray(userUUID string, email string, xrayAPI string) error {
    payload := map[string]interface{}{
        "method": "addUser",
        "params": []map[string]interface{}{
            {
                "id":      userUUID,
                "alterId": 0,
                "email":   email,
            },
        },
    }

    jsonData, err := json.Marshal(payload)
    if err != nil {
        return err
    }

    resp, err := http.Post(xrayAPI, "application/json", bytes.NewBuffer(jsonData))
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("向 Xray 添加用户失败: %s", resp.Status)
    }

    return nil
}
