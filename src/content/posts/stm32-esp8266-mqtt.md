---
title: "STM32 + ESP8266 实现 MQTT 数据上报"
date: 2026-03-27
description: "详细讲解如何使用STM32单片机配合ESP8266 WiFi模块，通过MQTT协议实现传感器数据的上报，附带完整代码和调试方法。"
tags: ["IoT", "Python"]
featured: false
---

物联网项目中，单片机采集传感器数据后需要上传到云端。MQTT是物联网通信的标准协议，轻量且可靠。本文教你在STM32+ESP8266上实现MQTT数据上报。

## 硬件准备

### 所需材料

| 组件 | 数量 | 说明 |
|------|------|------|
| STM32F103C8T6 | 1 | 主控芯片 |
| ESP8266-01S | 1 | WiFi模块 |
| DHT11 | 1 | 温湿度传感器 |
| USB转TTL | 1 | 调试用 |
| 面包板+杜邦线 | 若干 | - |

### 连接图

```
STM32F103              ESP8266-01S
----------             -----------
PA9 (TX)  ──────────── RX
PA10 (RX) ──────────── TX
3.3V    ────────────  VCC
GND     ────────────  GND

DHT11
----
DATA  ──────────── PA6
VCC   ──────────── 3.3V
GND   ──────────── GND
```

## 总体架构

```text
┌─────────────┐      UART       ┌─────────────┐    MQTT     ┌─────────────┐
│  STM32F103  │ ─────────────── │  ESP8266    │ ────────── │   Broker    │
│  (采集数据) │                 │  (WiFi/MQTT) │            │   (云端)    │
└─────────────┘                 └─────────────┘            └─────────────┘
     │                                                         │
     │ MQTT Topic: device/sensor                              │
     └─────────────────────────────────────────────────────────┘
```

## MQTT 协议基础

### 核心概念

| 概念 | 说明 |
|------|------|
| Broker | MQTT服务器，负责消息转发 |
| Publisher | 发布者，向主题发送消息 |
| Subscriber | 订阅者，接收主题消息 |
| Topic | 主题，消息的分类路径 |
| QoS | 服务质量（0/1/2三个级别） |

### 常用 Topic 命名

```
device/{device_id}/temperature    # 设备温度
device/{device_id}/humidity       # 设备湿度
device/{device_id}/status         # 设备状态
```

## STM32 代码实现

### 1. DHT11 驱动

```c
// dht11.h
#ifndef __DHT11_H__
#define __DHT11_H__

#include "stm32f10x.h"

void DHT11_Init(void);
uint8_t DHT11_Read_Data(uint8_t *temp, uint8_t *humi);

#endif
```

```c
// dht11.c
#include "dht11.h"
#include "delay.h"

#define DHT11_PORT GPIOA
#define DHT11_PIN  GPIO_Pin_6

void DHT11_Init(void) {
    GPIO_InitTypeDef GPIO_InitStructure;
    
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
    
    GPIO_InitStructure.GPIO_Pin = DHT11_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(DHT11_PORT, &GPIO_InitStructure);
}

void DHT11_Mode_Input(void) {
    GPIO_InitTypeDef GPIO_InitStructure;
    GPIO_InitStructure.GPIO_Pin = DHT11_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
    GPIO_Init(DHT11_PORT, &GPIO_InitStructure);
}

void DHT11_Mode_Output(void) {
    GPIO_InitTypeDef GPIO_InitStructure;
    GPIO_InitStructure.GPIO_Pin = DHT11_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(DHT11_PORT, &GPIO_InitStructure);
}

uint8_t DHT11_Init_Sensor(void) {
    uint8_t retry = 200;
    
    DHT11_Mode_Output();
    GPIO_ResetBits(DHT11_PORT, DHT11_PIN);
    delay_ms(18);
    GPIO_SetBits(DHT11_PORT, DHT11_PIN);
    delay_us(30);
    DHT11_Mode_Input();
    
    while(GPIO_ReadInputDataBit(DHT11_PORT, DHT11_PIN) && retry--) {
        delay_us(1);
    }
    
    if(retry == 0) return 1;
    retry = 200;
    
    while(!GPIO_ReadInputDataBit(DHT11_PORT, DHT11_PIN) && retry--) {
        delay_us(1);
    }
    
    return (retry == 0) ? 1 : 0;
}

uint8_t DHT11_Read_Byte(void) {
    uint8_t i, dat = 0;
    
    for(i = 0; i < 8; i++) {
        while(GPIO_ReadInputDataBit(DHT11_PORT, DHT11_PIN));
        delay_us(30);
        
        dat <<= 1;
        if(GPIO_ReadInputDataBit(DHT11_PORT, DHT11_PIN)) {
            dat |= 1;
        }
        
        while(!GPIO_ReadInputDataBit(DHT11_PORT, DHT11_PIN));
    }
    
    return dat;
}

uint8_t DHT11_Read_Data(uint8_t *temp, uint8_t *humi) {
    uint8_t buf[5];
    uint8_t i;
    
    if(DHT11_Init_Sensor()) return 1;
    
    for(i = 0; i < 5; i++) {
        buf[i] = DHT11_Read_Byte();
    }
    
    if(buf[0] + buf[1] + buf[2] + buf[3] == buf[4]) {
        *humi = buf[0];
        *temp = buf[2];
        return 0;
    }
    
    return 1;
}
```

### 2. ESP8266 MQTT 客户端

```c
// esp8266_mqtt.h
#ifndef __ESP8266_MQTT_H__
#define __ESP8266_MQTT_H__

#include "stm32f10x.h"
#include "stdio.h"
#include "string.h"

#define MQTT_BROKER    "broker.emqx.io"  // 免费公共Broker
#define MQTT_PORT       1883
#define MQTT_CLIENT_ID  "stm32_client_001"
#define MQTT_USER       ""
#define MQTT_PASS       ""

#define MQTT_KEEPALIVE  60
#define MQTT_QOS        0

void ESP8266_MQTT_Init(void);
uint8_t ESP8266_MQTT_Connect(void);
uint8_t ESP8266_MQTT_Publish(const char *topic, const char *payload);

void ESP8266_Send_Cmd(char *cmd, char *ack, uint16_t timeout);

#endif
```

```c
// esp8266_mqtt.c
#include "esp8266_mqtt.h"
#include "usart.h"
#include "delay.h"

extern UART_HandleTypeDef UART1_Handler;

char mqtt_buffer[512];

// 发送AT指令
void ESP8266_Send_Cmd(char *cmd, char *ack, uint16_t timeout) {
    Usart_SendString(UART1, cmd);
    
    while(timeout--) {
        if(Usart_ReceiveByte(UART1, (uint8_t *)ack)) {
            if(strstr(mqtt_buffer, ack)) {
                memset(mqtt_buffer, 0, sizeof(mqtt_buffer));
                return;
            }
        }
        delay_ms(1);
    }
}

// MQTT CONNECT包构建
void MQTT_Connect(void) {
    uint16_t client_id_len = strlen(MQTT_CLIENT_ID);
    uint16_t user_len = strlen(MQTT_USER);
    uint16_t pass_len = strlen(MQTT_PASS);
    
    uint8_t connect_packet[100];
    uint16_t packet_len = 0;
    
    // Fixed Header
    connect_packet[packet_len++] = 0x10;  // CONNECT
    // Remaining Length (待计算)
    
    // Variable Header
    connect_packet[packet_len++] = 0x00;  // Protocol Name Length
    connect_packet[packet_len++] = 0x04;
    connect_packet[packet_len++] = 'M';
    connect_packet[packet_len++] = 'Q';
    connect_packet[packet_len++] = 'T';
    connect_packet[packet_len++] = 'T';
    connect_packet[packet_len++] = 0x04;  // Protocol Level 4
    connect_packet[packet_len++] = 0x02;  // Connect Flag
    connect_packet[packet_len++] = 0x00;  // Keep Alive MSB
    connect_packet[packet_len++] = MQTT_KEEPALIVE;
    
    // Payload
    // Client ID
    connect_packet[packet_len++] = (client_id_len >> 8) & 0xFF;
    connect_packet[packet_len++] = client_id_len & 0xFF;
    memcpy(&connect_packet[packet_len], MQTT_CLIENT_ID, client_id_len);
    packet_len += client_id_len;
    
    // User & Password (如果有)
    if(user_len > 0) {
        connect_packet[packet_len++] = (user_len >> 8) & 0xFF;
        connect_packet[packet_len++] = user_len & 0xFF;
        memcpy(&connect_packet[packet_len], MQTT_USER, user_len);
        packet_len += user_len;
    }
    
    // 计算并设置Remaining Length
    uint8_t remaining = packet_len - 2;
    connect_packet[1] = remaining;
    
    // 发送
    for(uint16_t i = 0; i < packet_len; i++) {
        Usart_SendByte(UART1, connect_packet[i]);
    }
}

// MQTT PUBLISH包构建
void MQTT_Publish(const char *topic, const char *payload) {
    uint16_t topic_len = strlen(topic);
    uint16_t payload_len = strlen(payload);
    uint16_t packet_len = 2 + topic_len + payload_len;
    
    uint8_t packet[512];
    uint16_t idx = 0;
    
    // Fixed Header
    packet[idx++] = 0x30;  // PUBLISH
    packet[idx++] = packet_len;
    
    // Topic
    packet[idx++] = (topic_len >> 8) & 0xFF;
    packet[idx++] = topic_len & 0xFF;
    memcpy(&packet[idx], topic, topic_len);
    idx += topic_len;
    
    // Payload
    memcpy(&packet[idx], payload, payload_len);
    idx += payload_len;
    
    // 发送
    for(uint16_t i = 0; i < idx; i++) {
        Usart_SendByte(UART1, packet[i]);
    }
}

uint8_t ESP8266_MQTT_Init(void) {
    delay_ms(2000);  // 等待上电稳定
    
    ESP8266_Send_Cmd("AT+RST\r\n", "OK", 5000);
    delay_ms(2000);
    
    ESP8266_Send_Cmd("AT+CWMODE=1\r\n", "OK", 3000);
    ESP8266_Send_Cmd("AT+CWJAP=\"你的WiFi\",\"密码\"\r\n", "OK", 10000);
    
    return 0;
}

uint8_t ESP8266_MQTT_Connect(void) {
    char cmd[100];
    sprintf(cmd, "AT+CIPSTART=\"TCP\",\"%s\",%d\r\n", MQTT_BROKER, MQTT_PORT);
    
    ESP8266_Send_Cmd(cmd, "CONNECT", 5000);
    delay_ms(100);
    
    MQTT_Connect();
    
    return 0;
}

uint8_t ESP8266_MQTT_Publish(const char *topic, const char *payload) {
    MQTT_Publish(topic, payload);
    return 0;
}
```

### 3. 主程序

```c
// main.c
#include "stm32f10x.h"
#include "usart.h"
#include "delay.h"
#include "dht11.h"
#include "esp8266_mqtt.h"

char pub_topic[50];
char pub_payload[100];

int main(void) {
    uint8_t temperature, humidity;
    uint32_t last_publish = 0;
    
    // 初始化
    delay_init();
    Usart1_Init(115200);
    DHT11_Init();
    
    printf("System Started!\r\n");
    
    // 连接WiFi和MQTT Broker
    ESP8266_MQTT_Init();
    ESP8266_MQTT_Connect();
    
    printf("MQTT Connected!\r\n");
    
    while(1) {
        // 每10秒上报一次
        if(HAL_GetTick() - last_publish > 10000) {
            if(DHT11_Read_Data(&temperature, &humidity) == 0) {
                sprintf(pub_topic, "device/stm32/temperature");
                sprintf(pub_payload, "{\"temp\":%d}", temperature);
                ESP8266_MQTT_Publish(pub_topic, pub_payload);
                
                sprintf(pub_topic, "device/stm32/humidity");
                sprintf(pub_payload, "{\"humi\":%d}", humidity);
                ESP8266_MQTT_Publish(pub_topic, pub_payload);
                
                printf("Published: Temp=%d, Humi=%d\r\n", temperature, humidity);
            }
            
            last_publish = HAL_GetTick();
        }
    }
}
```

## Python 后端接收

使用Python快速搭建MQTT接收服务：

```python
# mqtt_subscriber.py
import paho.mqtt.client as mqtt
import json
from datetime import datetime

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    # 订阅主题
    client.subscribe("device/stm32/#")

def on_message(client, userdata, msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    topic = msg.topic
    payload = json.loads(msg.payload.decode())
    
    print(f"[{timestamp}] Topic: {topic}")
    print(f"[{timestamp}] Data: {payload}")
    
    # 这里可以存入数据库
    save_to_database(topic, payload)

def save_to_database(topic, data):
    # 使用SQLite示例
    import sqlite3
    
    conn = sqlite3.connect('sensor_data.db')
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sensor_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic TEXT,
            data TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    cursor.execute(
        'INSERT INTO sensor_log (topic, data) VALUES (?, ?)',
        (topic, str(data))
    )
    
    conn.commit()
    conn.close()

# 创建客户端
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

# 连接Broker
broker = "broker.emqx.io"
port = 1883

client.connect(broker, port, 60)

print("Starting MQTT Subscriber...")
client.loop_forever()
```

## 测试验证

### 1. 运行Python接收端

```bash
python mqtt_subscriber.py
```

### 2. 烧录STM32程序

使用ST-Link或J-Link烧录hex文件。

### 3. 观察数据

应该能看到类似输出：

```
[2026-03-27 21:30:01] Topic: device/stm32/temperature
[2026-03-27 21:30:01] Data: {'temp': 25}
[2026-03-27 21:30:01] Topic: device/stm32/humidity
[2026-03-27 21:30:01] Data: {'humi': 60}
```

## 常见问题

### 1. AT指令无响应
- 检查TX/RX连接是否正确
- 确认波特率匹配（ESP8266默认115200）
- 检查电平是否匹配

### 2. WiFi连接失败
- 确认WiFi名称和密码正确
- 确保WiFi是2.4G频段（ESP8266不支持5G）

### 3. MQTT连接失败
- 确认Broker地址和端口正确
- 检查防火墙是否阻止1883端口
- 尝试使用公共测试Broker

## 进阶功能

### 心跳保活

```c
// 每30秒发送MQTT PING包
void MQTT_Ping(void) {
    uint8_t ping_packet[2] = {0xC0, 0x00};
    for(int i = 0; i < 2; i++) {
        Usart_SendByte(UART1, ping_packet[i]);
    }
}
```

### OTA升级

可以通过MQTT接收固件更新指令，实现远程升级。

## 总结

本文实现了：
- ✅ STM32 DHT11传感器数据采集
- ✅ ESP8266 WiFi连接
- ✅ MQTT协议数据上报
- ✅ Python后端数据接收

完整的物联网数据采集链路搭建完成！

---

有问题欢迎留言讨论！
