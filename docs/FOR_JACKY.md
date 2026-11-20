# 給 Jacky

只放需要你處理或想聽你意見的事，處理完就刪。沒回的意見題照預設做。

1. **第五段（⑤ 公會門外的賒帳街）做完了，請玩**（整章都可以從頭玩；②～⑤ 都還沒有人玩過）：[latest](https://github.com/twjackysu/curses-too-useful/releases/tag/latest) 下載 →「**新遊戲**」→ 公會大廳 → **走出大門就是賒帳街**（主線只要把空籃子送到藥房、再從東門出去，約 5 分鐘；右上角列了四件可選的事：試戴街尾的詛咒戒指、聽席菈講她的藥單、找訓練場的鐵盾、麵攤地下室的東西，全做約 15 分鐘）→ 森林 → 祭壇 → 回公會 →「第一章　完」，整章約 40～65 分鐘。新的按鍵：**Tab 裝備面板**（開著時 F 戴上／拿下飾品）、**1** 喝席菈給的毒藥。想知道：①街上看不看得懂要去哪、可選的事有沒有自己想去做 ②試戴戒指時面板自己打開會不會太突然、看不看得懂「刺痛 → 回血」③地下室的兩種解法（油燈／轉閥）找不找得到 ④之前問過的照舊：大廳會不會一直在看對話、森林與魔像會不會迷路或太難、凝視要「站到那道光上」、遠處的東西會不會突然跳出來、換關卡黑畫面多久。不想玩可以看 CI 每次拍的截圖（Releases 的 `screens`，50～56 是這條街）。劇本沒寫、我自己定的在 `DECISIONS.md` 的 D-313。
2. **Tripo 佇列有 9 個待產（約 425 點）**：公會坐著的客人 `guild_patron_a`～`c`（約 165 點）、森林的另外兩種樹 `prop_corrupt_tree_tall`／`_low`（約 40 點）、**11/20 加的賒帳街四個人** `town_pharmacist`（藥房店主）、`town_apprentice`（小學徒）、`town_noodle_vendor`（麵攤攤主）、`town_warehouse_uncle`（倉庫大叔）（約 220 點；沒產之前是程式拼的人偶，顏色不一樣）。產出來我下一輪接上（位置與 id 都留好了）。餘額約 1985 點。
3. **下一輪開始 ⑥ 森林的斷軌事件**（增補稿時段 B：阿展與卡在坡上的手推車、兩條救車路線；加上「回程經藥房」與開頭的「止血棉與席菈的疑問」）：開工那一輪排阿展的 Tripo（約 55 點）。想先打磨或先做別的，在回覆寫一句就改。
4. **實機效能（有空時跑一次，約 2 分鐘）**：雲端只有軟體算圖、量不出 fps。解壓 latest 之後在資料夾裡開 PowerShell 跑四次 `.\CursesTooUseful.exe ++ --benchmark --bench-route=entrance`（再把 `entrance` 換成 `deep`、`altar`、`guild`），每次約 30 秒、自己結束，結果在 `%APPDATA%\CursesTooUseful\benchmark\` 的四個 json——把它們丟進 `art-inbox/`（或貼在回覆）我就知道哪裡要省。之後才需要的：Steamworks 帳號／App ID／商店頁。（11/14 改名之後，你本機的 clone 要跑一次 `git remote set-url origin https://github.com/twjackysu/curses-too-useful.git`；舊的 `%APPDATA%\YumingCity` 資料夾可以刪。）

---

## 回覆

在這一行下面寫，每則開頭寫日期（例如 `2026-11-15：…`）。loop 每輪先讀這裡，處理完在你的字下面加一行「→ 已處理（時間、commit）」，不改你寫的字。

- 暫停 loop：寫一則只有「暫停」或「STOP」；恢復寫「繼續」。
