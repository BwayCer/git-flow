輯步步
=======


以腳本來執行預設情境的 `git` 命令，
透過模擬執行來理解如何操作及其用途。

預設情境：
  1. 建立專案
  2. 提交命名規則
  3. 團隊分工
  4. 修正舊版本錯誤。

![](../../mmrepo/gitStep.gif)
_（示意圖，會因文件更新而不同。）_



## 使用說明


```
./run.sh
```

或者可透過自動執行

```
./run.sh --auto <間隔時間的數字>
```

**※ `run.sh` 會在當前目錄下建立 "READMD.md.tem" 文件及 ".git"、"flow.log" 兩目錄。**



### 畫面


```
--- 命令排程 ---              <-- 顯示已執行、當前、待執行的命令

(---)
(---)
(000)$ git init               <-- 當前命令
(001)$ ...
(002)$ ...

--- 命令描述 ---              <-- 當前命令的說明

# 建立專案

--- 命令輸出 ---              <-- 執行當前命令所輸出的內容

Initialized empty Git repository in ...

（按 <確認鍵> 繼續 ...）      <-- 提示動作，依提示繼續執行
```



### 監聽


**查看輯線圖：**

```
watch -n <間隔時間> -c \
    git log --graph --all --color\
        '--pretty="format:%C(yellow)%h %C(white)%ad | %s%C(yellow)%d %C(white)[%an]"' \
        --date="format:%H:%M:%S"
```


**查看輯日誌：**

```
watch -n <間隔時間> -c git reflog --color
```

