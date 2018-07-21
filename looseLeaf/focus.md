要點
=======


**空提交：**

  * `git commit --allow-empty`

第一筆資料難以變更，建議使用空提交當基底。


**提交綴字：**

  * **增補**： 當加入「新」這種概念時使用。
  * **優化**： 有「**更改**」或「**更正**」後綴，
               當修改與用戶無關的調整或未發布版本的錯誤時使用。
  * **修改**： 有「**更正**」後綴，當修改發布版本的錯誤時使用。
  * **合併**： 有「**更正**」後綴可選，當子項目併入其主項目時使用。
  * **版本**： 當發布版本（合併到 \"master\"）時使用。
  * **文件**： 有「**排版**」、「**編寫**」或「**修訂**」子前綴，
               當修改與文件相關的調整結構、增減內容或更改不實資訊時使用。


**區分功能分支：**

  * `git merge --no-ff`（保留線圖式合併）


**嫁接：**

  * `git rebase`
  * `git rebase --onto`（跳躍式嫁接）
  * `git rebase --preserve-merges`（保留線圖式嫁接）

善用嫁接，避免看見彩虹。

![](../mmrepo/rainbowLineGraph.jpg)
