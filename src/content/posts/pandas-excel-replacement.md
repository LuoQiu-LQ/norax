---
title: "Python 数据分析：用 Pandas 替代 Excel"
date: 2026-03-27
description: "详细介绍了如何使用Python的Pandas库进行数据分析，包括数据读取、清洗、转换、聚合等操作，让你的数据分析工作更高效。"
tags: ["Python"]
featured: false
---

Excel是强大的数据分析工具，但当数据量变大、流程需要自动化时，Pandas就是更好的选择。本文将带你从零开始，用Pandas替代Excel完成常见的数据分析任务。

## 为什么选择 Pandas

| 特性 | Excel | Pandas |
|------|-------|--------|
| 数据量 | 通常<100万行 | 可处理GB级数据 |
| 自动化 | 手动操作 | 代码驱动 |
| 可复现 | 难以追踪 | 版本控制友好 |
| 协作 | 多人编辑困难 | Git协作无缝 |

## 环境准备

```bash
pip install pandas numpy openpyxl
```

```python
import pandas as pd
import numpy as np
```

## 数据读取与导出

### 读取各种格式

```python
# 读取Excel
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')

# 读取CSV
df = pd.read_csv('data.csv', encoding='utf-8')

# 读取JSON
df = pd.read_json('data.json')

# 读取SQL
import sqlite3
conn = sqlite3.connect('database.db')
df = pd.read_sql('SELECT * FROM table', conn)
```

### 数据导出

```python
# 导出为Excel
df.to_excel('output.xlsx', index=False)

# 导出为CSV
df.to_csv('output.csv', index=False)

# 导出为HTML
df.to_html('output.html')
```

## 数据探索

### 查看数据概况

```python
# 查看前几行
df.head(10)

# 查看数据类型
df.dtypes

# 查看基本统计
df.describe()

# 查看行列数
df.shape

# 查看列名
df.columns.tolist()
```

### 数据筛选

```python
# 单条件筛选
df[df['年龄'] > 25]

# 多条件筛选
df[(df['年龄'] > 25) & (df['城市'] == '北京')]

# 使用query方法
df.query('年龄 > 25 and 城市 == "北京"')
```

## 数据清洗

### 处理缺失值

```python
# 查看缺失值
df.isnull().sum()

# 删除缺失值
df.dropna()

# 填充缺失值
df.fillna(0)                           # 用0填充
df.fillna(df.mean())                   # 用均值填充
df['列名'].fillna('默认值', inplace=True)

# 插值填充
df.interpolate()
```

### 处理重复值

```python
# 查看重复行
df.duplicated()

# 删除重复行
df.drop_duplicates()

# 按列删除重复
df.drop_duplicates(subset=['姓名', '手机号'])
```

### 数据类型转换

```python
# 转换类型
df['日期'] = pd.to_datetime(df['日期'])
df['金额'] = pd.to_numeric(df['金额'])

# 字符串处理
df['姓名'] = df['姓名'].str.strip()
df['手机'] = df['手机'].str.replace('-', '')
```

## 数据转换

### 新增计算列

```python
# 简单计算
df['总价'] = df['单价'] * df['数量']

# 条件计算
df['等级'] = df['分数'].apply(
    lambda x: 'A' if x >= 90 else 'B' if x >= 80 else 'C'
)

# 使用map
df['城市代码'] = df['城市'].map({'北京': 'BJ', '上海': 'SH'})
```

### 数据重塑

```python
# 透视表
pivot = df.pivot_table(
    values='销售额',
    index='月份',
    columns='产品',
    aggfunc='sum'
)

# 熔化（宽表转长表）
df_melted = df.melt(id_vars=['日期'], value_vars=['产品A', '产品B'])
```

## 数据聚合

### 分组统计

```python
# 基本分组
grouped = df.groupby('部门')
grouped['工资'].mean()

# 多列分组
df.groupby(['部门', '职位'])['工资'].agg(['mean', 'max', 'min'])

# 使用agg自定义
df.groupby('部门').agg({
    '工资': ['mean', 'sum'],
    '人数': 'count'
})
```

### 排序

```python
# 单列排序
df.sort_values('销售额', ascending=False)

# 多列排序
df.sort_values(['部门', '工资'], ascending=[True, False])
```

## 实战案例：销售数据分析

```python
import pandas as pd
import matplotlib.pyplot as plt

# 读取数据
df = pd.read_excel('sales.xlsx')

# 数据清洗
df['日期'] = pd.to_datetime(df['日期'])
df['月份'] = df['日期'].dt.to_period('M')
df['金额'] = pd.to_numeric(df['金额'], errors='coerce')

# 按月统计
monthly_sales = df.groupby('月份')['金额'].sum()

# 按产品统计
product_sales = df.groupby('产品')['金额'].agg(['sum', 'mean', 'count'])

# 按地区和产品交叉统计
cross_tab = pd.pivot_table(
    df, 
    values='金额', 
    index='地区', 
    columns='产品', 
    aggfunc='sum',
    fill_value=0
)

# 可视化
monthly_sales.plot(kind='bar', figsize=(12, 6))
plt.title('月度销售额')
plt.tight_layout()
plt.savefig('monthly_sales.png')
```

## 性能优化技巧

### 大数据处理

```python
# 分块读取
for chunk in pd.read_csv('big_data.csv', chunksize=10000):
    process(chunk)

# 指定数据类型减少内存
df = pd.read_csv('data.csv', dtype={'id': 'int32', 'value': 'float32'})
```

### 向量化操作

```python
# 避免循环，使用向量化
df['总价'] = df['单价'] * df['数量']  # 正确

# 而不是
for i in range(len(df)):
    df.loc[i, '总价'] = df.loc[i, '单价'] * df.loc[i, '数量']  # 错误
```

## 总结

Pandas相比Excel的优势在于：

1. **处理大数据** - 轻松处理数百万行数据
2. **自动化流程** - 一键重复执行复杂分析
3. **可复现性** - 代码即文档，便于审核和分享
4. **版本控制** - 可纳入Git进行版本管理
5. **与其他工具集成** - 可配合Jupyter、ML库使用

建议从日常小任务开始，逐步将Excel工作迁移到Pandas，你会发现效率提升是显著的！

---

有任何问题欢迎留言交流！
