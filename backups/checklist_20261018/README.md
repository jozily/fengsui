# 修改前备份

- 45 个技能：`*_remake.lua`，原字节保存，未改技能 ID。来源为本轮修改前的 `HEAD`。具体路径和 SHA-256 见 `manifest.json`。
- 3 份各子包旧 `init.lua` 描述表：保留修改前描述。另保存本次分包调整前的 `fengsui_hebi_init_remake2.lua`、`fengsui_liwu_init_remake2.lua`。
- 潘岳资源改名为潘安时，旧立绘和阵亡语音也保存在本目录。
- `historical_remakes/`：64 份修改前已有 `Remake/Remake2/Remake3` 文件，原字节保存。
- 此目录不由游戏自动加载，因此归档文件中的旧技能 ID 不会与新版冲突。技能目录内原有的 Remake 文件保留，重复 ID 已校正为对应文件名，原字节副本见 `historical_remakes/`。
- 若同名备份已存在则保留，不覆盖；再次备份应使用 `_remake2`、`_remake3` 顺延。

`test_results.json` 为本轮首次全量测试结果；`new_descriptions.json` 记录此次按清单同步的描述。最终逐项结果见包根目录 `fengsui_checklist.md`。
