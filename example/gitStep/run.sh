#!/bin/bash
# 輯步步


##shStyle 腳本環境

_br="
"

_fN=`tput sgr0`
_fRedB=`tput setaf 1``tput bold`
_fGreB=`tput setaf 2``tput bold`
_fYelB=`tput setaf 3``tput bold`
_fCya=`tput setaf 6`


##shStyle 共享變數


exec_cmdList=()
exec_describeList=()


##shStyle 函式庫


fnNum3Format() {
    printf "%03d" "$1"
}

fnExec() {
    local describe="$1"
    local cmd="$2"

    local len=${#exec_cmdList[@]}

    exec_cmdList[     $len]=$cmd
    exec_describeList[$len]=$describe
}

fnExecStart() {
    local method="$1"
    local sleepSecond="$2"

    local idx len
    local promptMsg

    [ "$method" == "--auto" ] \
        && promptMsg="等待 $sleepSecond 後" \
        || promptMsg="按 <確認鍵> "

    len=${#exec_cmdList[@]}
    for idx in `seq 0 $((len - 1))`
    do
        clear
        echo "$_fCya--- 命令排程 ---$_fN"
        echo
        fnExecStart_printfCmd $idx $((idx - 2))
        fnExecStart_printfCmd $idx $((idx - 1))
        fnExecStart_printfCmd $idx $idx
        fnExecStart_printfCmd $idx $((idx + 1))
        fnExecStart_printfCmd $idx $((idx + 2))
        echo
        echo "$_fCya--- 命令描述 ---$_fN"
        echo
        echo "${exec_describeList[$idx]}"
        echo
        echo "$_fCya--- 命令輸出 ---$_fN"
        echo
        printf "$_fCya（${promptMsg}開始執行）$_fN"
        [ "$method" == "--auto" ] && sleep $sleepSecond && echo || read
        printf "\e[A\r\e[K";
        sh -c "${exec_cmdList[$idx]}"
        tem=$?
        if [ $tem -ne 0 ]; then
            echo -e "\n（退出碼： $tem）"
            [ "$method" == "--auto" ] && exit $tem
        fi
        echo
        printf "$_fCya（${promptMsg}繼續 ...）$_fN"
        [ "$method" == "--auto" ] && sleep $sleepSecond && echo || read
    done
}
fnExecStart_printfCmd() {
    local nowQueueIdx=$1
    local queueIdx=$2

    local cmd cmdFormat
    local numberFormat=`fnNum3Format $queueIdx`

    [ $queueIdx -ge 0 ] \
        && cmd="${exec_cmdList[$queueIdx]}" \
        || cmd="" \

    [ -z "$cmd" ] && echo "(---)" && return

    [ $queueIdx -lt $nowQueueIdx ] \
        && [ "`echo "$cmd" | wc -l`" -gt 1 ] \
        && cmd=`echo "$cmd" | sed -n "1p"`" ..."

    cmdFormat="$_fGreB($numberFormat)$_fN\$ "
    if [ $queueIdx -eq $nowQueueIdx ]; then
        cmdFormat+="$_fYelB%s$_fN\n"
    else
        cmdFormat+="%s\n"
    fi

    printf "$cmdFormat" "$cmd"
}

fnTool_commit() {
    local describe="$1"
    local author="$2"
    local msg="$3"

    local cmdIdx=${#exec_cmdList[@]}

    case $# in
        3 )
            author=" -c user.name=\"$author\""
            ;;
        * )
            msg=$author
            author=""
            ;;
    esac

    local fileName="execCount_${cmdIdx}.txt"

    fnExec "$describe" "echo \"---\" > \"flow.log/$fileName\""
    fnExec "$describe" "git add \"flow.log/$fileName\""
    fnExec "$describe" "git${author} commit -m \"$msg\""
}

fnTool_mergeBranch() {
    local method="$1"
    local describe="$2"
    local trunk="$3"
    local branch="$4"
    local msg="$5"

    fnExec "$describe" "git checkout $trunk"
    fnExec "$describe" "git merge --no-ff $branch -m \"$msg\""
    fnExec "$describe" "git branch $method $branch"
}

fnTool_release() {
    local describeMsg="$1"
    local version="$2"

    local describe

    describe=$describeMsg$_br
    describe+=$_br"說明："
    describe+=$_br"  發布 $version。"

    fnExec "$describe" 'git checkout master'
    fnExec "$describe" "git merge --no-ff develop -m \"版本 $version\""
    fnTool_commit "$describe" "文件 編寫 $version"
    fnExec "$describe" "git tag $version"
    fnExec "$describe" 'git rebase master develop'
    fnExec "$describe" 'git checkout master'
}

fnTool_brancOps() {
    local branchName="$1"

    local custom
    local title="## 創建 $branchName 維運分支"

    custom=$title$_br
    custom+=$_br"說明："
    custom+=$_br"  當 develop 分支開始開發新功能時創立 ops 維運分支，"
    custom+=$_br"  其版本號為其當前或往前推至非錯誤更正的發布版本。"
    fnExec "$custom" "git branch $branchName master"
}


##shStyle ###


# 特別允許使用下列參數
# title
# describe
# customDescribe


#
# Git init
#

title="## 建立專案"

fnExec "$title" 'mkdir "flow.log"'

fnExec "$title" 'git init'

customDescribe="$title$_br
說明：
  解決中文亂碼問題。"
fnExec "$customDescribe" 'git config core.quotepath false'

customDescribe="$title$_br
說明：
  因為第一筆資料難以變更，建議使用空提交當基底。"
fnExec "$customDescribe" 'git commit --allow-empty -m "~~~"'

customDescribe="$title$_br
說明：
  簡述固定內容並為專案定名。"
fnExec "$customDescribe" 'echo -e "輯流程設計\n=======" > README.md.tem'
fnExec "$customDescribe" 'git add README.md.tem'
fnExec "$customDescribe" 'git commit -m "輯流程設計"'

fnExec "$title" 'git branch develop'


#
# Git commitName
# item_A, ops_B
#

# Git # A

title="## 提交命名規則"
describe_commitName="$title$_br
分類命名：
  * 增補： 當加入「新」這種概念時使用。
  * 優化： 有「更改」或「更正」後綴，
           當修改與用戶無關的調整或未發布版本的錯誤時使用。
  * 修改： 有「更正」後綴，當修改發布版本的錯誤時使用。
  * 合併： 有「更正」後綴可選，當子項目併入其主項目時使用。
  * 版本： 當發布版本（合併到 \"master\"）時使用。
  * 文件： 有「排版」、「編寫」或「修訂」子前綴，
           當修改與文件相關的調整結構、增減內容或更改不實資訊時使用。"

customDescribe="$describe_commitName$_br
補充：
  * 若增補、優化、修改、文件要提交於同一筆紀錄點，須以 \"；\" 分隔，
    並以 修改、優化、增補、文件 的順序排列，或者使用隱藏欄位。
    如：
      1.
      xxxxxxx 修改 (...)更正； 優化 (...)更改； 增補 (...)； 文件 (...)
      2.
      xxxxxxx 修改 (本次提交主題)更正；

      修改 (...)更正
      優化 (...)更改
      增補 (...)
      文件 (...)
  * 若同一筆分類中提及兩事項須以 \"、\" 分隔，或者使用隱藏欄位。
    如：
      1.
      xxxxxxx 增補 加入 a.js, b.js 兩文件、引入 A, B 兩模組
      2.
      xxxxxxx 增補 (本次提交主題)

      加入 a.js, b.js 兩文件
      引入 A, B 兩模組"
fnExec "$customDescribe" 'echo "提交命名規則 - 補充。"'

describe="$describe_commitName$_br
情況劇：
  1. 完成專案雛形並發布 v0.1.0 版本。
  2. 剛發布立馬發現一項錯誤並更正。"

fnExec "$describe" 'git checkout -b item_A develop'
fnTool_commit "$describe" '增補 (...)'
fnTool_commit "$describe" '文件 編寫 (...)'

customDescribe="$describe$_br
說明：
  以 \"；\" 分隔的多分類共同提交。"
fnTool_commit "$customDescribe" "優化 (...)更正； 優化 (...)更改； 增補 (...)； 文件 (...)"

customDescribe="$describe$_br
說明：
  使用隱藏欄位的多分類共同提交。"
fnTool_commit "$customDescribe" "優化 (ooo)更正

優化 (...)更正
優化 (...)更改
增補 (...)
文件 (...)"

customDescribe="$describe$_br
說明：
  以 \"、\" 分隔的多事項提交。"
fnTool_commit "$customDescribe" '優化 把 A 更名為 B、小地方 更改'

customDescribe="$describe$_br
說明：
  使用隱藏欄位的多事項提交。"
fnTool_commit "$customDescribe" "優化 把 A 更名為 B 更改

把 A 更名為 B
小地方更改(此處的更改不是後綴，使用調整亦可)"

fnTool_mergeBranch -d "$describe" "develop" "item_A" "合併 A 項目"

fnTool_release "$describe" "v0.1.0"

# Git # B

fnExec "$describe" 'git checkout -b ops_B master'
customDescribe="$describe$_br
說明：
  在合併更正中也能有 優化、增補 的提交。"
fnTool_commit "$customDescribe" '增補 (...)'
fnTool_commit "$customDescribe" '優化 (...)更改'
fnTool_commit "$describe" '修改 (...)更正'
fnExec "$describe" 'git checkout master'
fnExec "$describe" 'git merge --no-ff ops_B -m "合併 ops_B 項目更正"'
fnExec "$describe" "git tag v0.1.1"
fnExec "$describe" 'git rebase master develop'
fnExec "$describe" 'git branch -d ops_B'

fnExec "$describe" 'git checkout master'


#
# Git rebaseP
# item_A, ops_B
#

fnTool_brancOps "v0.1.0-ops"

title="## 團隊分工"
describe="$title$_br
情況劇：
  我 與 anotherA 共同開發並發布 v0.3.1 版本。
  項目：
    * item_C： 需求端項目至程式端時再分工，拆分兩子項。
      * item_C_subA：
        * 一筆增補提交由 我 完成。
        * 一筆增補提交由 anotherA 完成。
      * item_C_subB：
        * 一筆增補提交由 anotherA 完成。
    * item_D：
      * 一筆增補提交由 anotherA 完成。"

customDescribe="$describe$_br
補充：
  * 需求到程式實做時最多就畫到子項目，
    不是指程式分支（開發中使用的分支），而是線圖保留的分支。
    所以由程式分支要合併回線圖時需要嫁接 \`rebase\` 處理。
  * 保留線圖嫁接 \`rebase --preserve-merges\`。
   （此選項無法搭配 \`--keep-empty\` 使用去嫁接空提交）
  * 合併應為管理者的任務。
    而嫁接最新基底則屬開發者任務，但若因同時送審時亦可請管理者協助嫁接。

（嫁接及保留線圖式嫁接）
"
fnExec "$customDescribe" 'echo "團隊分工 - 補充。"'

# Git # C # A # me

fnExec "$describe" 'git branch item_C develop'
fnExec "$describe" 'git branch item_C_subA item_C'
customDescribe="$describe$_br
說明：
  item_C_subA_anotherA 與 item_C_subA_me 為同時期開發的程式分支 。"
fnExec "$customDescribe" 'git branch item_C_subA_anotherA item_C_subA'
fnExec "$customDescribe" 'git checkout -b item_C_subA_me item_C_subA'
fnTool_commit "$describe" '增補 (...)'
fnExec "$describe" 'git rebase item_C_subA_me item_C_subA'
fnExec "$describe" 'git branch -D item_C_subA_me'

# Git # C # A # anotherA

customDescribe="$describe$_br
說明：
  程式分支 item_C_subA_anotherA 與 item_C_subA_me 同時期開始開發，
  但現在 item_C_subA_me 已複審完成，
  使得所在基底並非團隊的當前狀態，
  此時就須對分支做嫁接。

  1. 維護線圖。
  2. 避免嫁接後又要再次送審。"
fnExec "$customDescribe" 'git checkout item_C_subA_anotherA'
fnTool_commit "$customDescribe" 'anotherA' '增補 (...)'
fnExec "$customDescribe" 'git -c user.name=anotherA rebase item_C_subA item_C_subA_anotherA'
fnExec "$customDescribe" 'git -c user.name=anotherA rebase item_C_subA_anotherA item_C_subA'
fnExec "$customDescribe" 'git branch -D item_C_subA_anotherA'

# Git # C # A

customDescribe="$describe$_br
說明：
  由 item_C 的管理者負責合併。"
fnTool_mergeBranch -d "$customDescribe" "item_C" "item_C_subA" "合併 C 項目 - A 子項"

# Git # C # B

fnExec "$describe" 'git checkout -b item_C_subB item_C'
fnTool_commit "$describe" 'anotherA' '增補 (...)'
fnTool_mergeBranch -d "$customDescribe" "item_C" "item_C_subB" "合併 C 項目 - B 子項"

# Git # C # D

customDescribe="$describe$_br
說明：
  item_D 與 item_C 為同時期開發的程式分支，
  但比 item_C 早送交複審並通過。"
fnExec "$customDescribe" 'git checkout -b item_D develop'
fnTool_commit "$customDescribe" 'anotherA' '增補 (...)'
fnTool_mergeBranch -d "$customDescribe" "develop" "item_D" "合併 D 項目"

# Git # C

customDescribe="$describe$_br
說明：
  同上一步嫁接情況須要把 item_C 以 develop 為基底嫁接，
  但這次是保留線圖式嫁接。"
fnExec "$customDescribe" 'git rebase --preserve-merges develop item_C'

fnTool_mergeBranch -d "$describe" "develop" "item_C" "合併 C 項目"

fnTool_release "$describe" "v0.3.1"


#
# Git rebaseOnto
# item_E, ops_F
#

fnTool_brancOps "v0.3.1-ops"

title="## 修正舊版本錯誤"
describe="$title$_br
情況劇：
  1. 開發一項新項目。
  2. 在 v0.1.0 發現一項錯誤。"

customDescribe="$describe$_br
補充：
  * 錯誤更正必須對所有發布版更新。
  * 跳躍式嫁接 \`rebase --onto\`。

（跳躍式嫁接）
"
fnExec "$customDescribe" 'echo "修正舊版本錯誤 - 補充。"'

# Git # E

fnExec "$describe" 'git checkout -b item_E develop'
fnTool_commit "$describe" '增補 (...)'
fnTool_mergeBranch -d "$describe" "develop" "item_E" "合併 E 項目"

# Git # F

customDescribe="$describe$_br
說明：
  更正 v0.1.0 的錯誤。"
fnExec "$customDescribe" 'git checkout -b ops_F v0.1.0-ops'
fnTool_commit "$customDescribe" '修改 (...)更正'
fnExec "$customDescribe" 'git checkout v0.1.0-ops'
fnExec "$customDescribe" 'git merge --no-ff ops_F -m "合併 ops_F 項目更正"'
fnExec "$customDescribe" "git tag v0.1.2"
fnExec "$customDescribe" 'git rebase v0.1.0-ops ops_F'

customDescribe="$describe$_br
說明：
  使用跳躍式嫁接對所有發布版更新。"
fnExec "$customDescribe" 'git rebase --preserve-merges --onto v0.3.1-ops v0.1.1 ops_F'
fnExec "$customDescribe" "git tag v0.3.2"
fnExec "$customDescribe" 'git rebase v0.3.2 v0.3.1-ops'
fnExec "$customDescribe" 'git rebase --preserve-merges --onto develop v0.3.1 ops_F'
fnExec "$customDescribe" 'git rebase ops_F develop'
fnExec "$customDescribe" 'git branch -d ops_F'



# 開始執行
# fnExecStart

fnMain() {
    if [ "$1" == "--auto" ]; then
        if [ -z "`grep "^\([1-9][0-9]*\|[0-9]\)\(\.[0-9]*[1-9]\)\?$" <<< "$2"`" ]; then
            echo "$_fRedB\"--auto\" 選項值必須為指定間隔時間的數字。$_fN"
            exit
        fi
    fi

    local temCho
    local _pwd=`realpath "$PWD"`
    local filenameReadMe="$_pwd/README.md.tem"
    local dirnameGit="$_pwd/.git"
    local dirnameFlowLog="$_pwd/flow.log"

    if [ -e "$filenameReadMe" ] || [ -e "$dirnameGit" ] || [ -e "$dirnameFlowLog" ]; then
        echo "將$_fRedB刪除以下文件（目錄）$_fN，請確認："
        [ -e "$filenameReadMe" ] && echo "  * $filenameReadMe"
        [ -e "$dirnameGit"     ] && echo "  * $dirnameGit"
        [ -e "$dirnameFlowLog" ] && echo "  * $dirnameFlowLog"
        printf "（輸入 y/Y/yes/Yes 確認並繼續執行，反之則退出）："
        read temCho
        case "$temCho" in
            [yY] | yes | Yes )
                [ -e "$filenameReadMe" ] && rm -rf "$filenameReadMe"
                [ -e "$dirnameGit"     ] && rm -rf "$dirnameGit"
                [ -e "$dirnameFlowLog" ] && rm -rf "$dirnameFlowLog"
                ;;
            * )
                exit
                ;;
        esac
    fi

    if [ "$1" == "--auto" ]; then
        fnExecStart --auto $2
    else
        fnExecStart
    fi
}
fnMain "$@"

