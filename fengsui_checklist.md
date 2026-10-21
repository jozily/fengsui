# 烽燧清单逐项核对（2026-10-18）

本表按用户原编号记录。代码与描述核对完成；测试覆盖见末尾，不等同于全部组合已经实战验证。

| 编号 | 技能 | 核对及本次处理 | 源码 / 旧版备份 |
|---|---|---|---|
| 1 | 眷故 | 核对本回合首张基本牌/普通锦囊牌；珠联目标两种选项；每次牌使用不重复发动。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__juangu.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__juangu_remake.lua) |
| 2 | 申情 | 仅改描述：珠联璧合去掉【】；合璧保留点击解释。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__shenqing.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__shenqing_remake.lua) |
| 3 | 维后 | 改判成本暗置技能所在武将牌的另一张。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__weihou.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__weihou_remake.lua) |
| 4 | 矜才 | 每回合一次；使用者选择暗置并禁亮/未全亮则此牌无效，或令你获得牌。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__jincai.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__jincai_remake.lua) |
| 5 | 连徙 | 明暗置导致数量变化时触发；受影响角色弃一区伤害当前角色，或直接与你换副将。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__lianxi.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__lianxi_remake.lua) |
| 6 | 合珏 | 仅受伤后触发；至多两名含自己；按配对武将牌数量摸牌（同一角色两张配对武将牌摸两张），否则在所选角色中确定一人合璧。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__hejue.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__hejue_remake.lua) |
| 7 | 貉隙 | 摸牌阶段外从其他区域获得牌并进入手牌区后移装备；装备牌直接进入装备区不触发；由技能拥有者选择伤害或暗置禁亮。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__hexi.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__hexi_remake.lua) |
| 8 | 如晤 | 移除副将技标签；保留锁定技。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__ruwu.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__ruwu_remake.lua) |
| 9 | 毓尘 | 出牌阶段一次；副将易位，前后控制该牌且阴阳鱼相等者依次选择；变更选项消费后移除。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__yuchen.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__yuchen_remake.lua) |
| 10 | 遐容 | 双方全明置时各暗置一张并回复；自己受伤仅暗置技能牌；删除旧自动明置尾效。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__xiarong.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__xiarong_remake.lua) |
| 11 | 诒桑 | 记录本回合全场上一张使用/打出的牌；在当前牌记录上一张颜色；目标自行选择重铸。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__yisang.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__yisang_remake.lua) |
| 12 | 朝华 | 取消阶段一次限制；可选自己/异势力；先完成效果再失效；仅摸牌分支禁亮，重置分支移除选项。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__chaohua.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__chaohua_remake.lua) |
| 13 | 德象 | 按要求仅同步描述，保留旧代码。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__dexiang.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__dexiang_remake.lua) |
| 14 | 眷易 | 按要求仅同步描述：异势力比较对象为得牌角色与受赠角色。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__juanyi.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__juanyi_remake.lua) |
| 15 | 离室 | 按要求仅同步描述。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__lishi.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__lishi_remake.lua) |
| 16 | 黜光 | 阈值摸X并失效对应技能；皎宿/曜暝后效移入此处；复原为解除横置/翻面，额外出牌阶段在回合结束后；皎宿与曜暝共用一个本轮锁定标记。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__chuguang.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__chuguang_remake.lua) |
| 17 | 悲秋 | 在 GeneralRevealed、变更武将时结算；即使悲秋所在武将牌暗置也能监听，其他角色暗置不触发；“所念之人”标记使用固定文本。死亡后亮将触发逻辑按用户要求保留。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__beiqiu.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__beiqiu_remake.lua) |
| 18 | 悼离 | 全局监听仅用于捕捉其他角色死亡；额外出牌阶段在当前回合结束后立即插入，保留自身技能，国战标记永久保留，获得的牌带“悼离”文本标记并在额外阶段结束时清理。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__daoli.lua) / [辅助逻辑](pkg/fengsui_hebi/daoli_util.lua) |
| 19 | 仇讨 | 其他角色结束阶段；必须实际受伤且本回合获得牌数大于实际伤害；造成1点伤害。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__choutao.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__choutao_remake.lua) |
| 20 | 雍番 | 造成和受到伤害两个时机；以逸待劳仅指定自身和另一方。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__yongfan.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__yongfan_remake.lua) |
| 21 | 败族 | 已受伤且有牌；已确定势力各选一名其他角色；同时弃牌并比较类别，导致死亡后变更副将。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__baizu.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__baizu_remake.lua) |
| 22 | 军巍 | 阵列回合开始；暗置一张获得本回合付授，或明置一张获得阴阳鱼；回合结束清理临时技能。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__junwei.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__junwei_remake.lua) |
| 23 | 沉绩 | 保留主将锁定标签；队列和围攻关系兼容；删除旧标记数过多死亡效果。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__chenji.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__chenji_remake.lua) |
| 24 | 骤望 | 副将阴阳鱼-1；每个武将技能每轮一次；可作用自己，排除自身递归；知己知彼并摸牌。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__zhouwang.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__zhouwang_remake.lua) |
| 25 | 负胤 | 回合结束时牌堆底X张依次强制合法使用；不能使用者获得，存在不能使用牌时失去1体力。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__fuyin.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__fuyin_remake.lua) |
| 26 | 保国 | 限定/同势力濒死/小势力（排除未确定势力）；各同势力角色可选择执行；交至少X张，不足全交；回复并变更。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__baoguo.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__baoguo_remake.lua) |
| 27 | 陨星 | 回合开始/回合结束；摸一张再置顶一张；最终判定梅花视为红桃；移除旧红桃摸/黑桃弃。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__yunxing.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__yunxing_remake.lua) |
| 28 | 藏卷、剑合、饮冰 | 张华注册三技能；藏卷仅首次明置自身牌；剑合主将鱼-1并保留实体牌花色；饮冰仅对自己重复结算。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__cangjuan.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__cangjuan_remake.lua) / [剑合](pkg/fengsui_hebi/skills/fengsui_heg__jianhe.lua) / [饮冰](pkg/fengsui_hebi/skills/fengsui_heg__yinbing.lua) |
| 29 | 飨馈 | 其他角色回合开始展示一张，然后可正面交任意张异类别牌。 | [源码](pkg/fengsui_liwu/skills/fengsui_heg__xiangkui.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__xiangkui_remake.lua) |
| 30 | 扬名 | 回合结束同势力/本回合获飨馈牌时；统计本回合公开离开手牌区牌数，上限5。 | [源码](pkg/fengsui_liwu/skills/fengsui_heg__yangming.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__yangming_remake.lua) |
| 31 | 隐誉 | 删除徐庶（蜀）副将相关的移除/易位/技能修改尾效，描述同步。 | [源码](pkg/fengsui_liwu/skills/fengsui_heg__yinyu.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__yinyu_remake.lua) |
| 32 | 束阁 | 受伤后正面交牌、与来源拼点；无旧每轮限制；平局双方均没赢，按交牌花色确定伤害目标。 | [源码](pkg/fengsui_liwu/skills/fengsui_heg__shuge.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__shuge_remake.lua) |
| 33 | 清饰 | 弃黑色手牌或装备；无效后本轮禁用，或本次牌使用完成并进入弃牌堆后获得，支持嵌套。 | [源码](pkg/fengsui_liwu/skills/fengsui_heg__qingshi_jx.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__qingshi_jx_remake.lua) |
| 34 | 谙世 | 出牌阶段主动限一次；知己知彼结束后可让目标选择；调整至体力值或给你额外回合并失去技能。 | [源码](pkg/fengsui_liwu/skills/fengsui_heg__anshi.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__anshi_remake.lua) |
| 35 | 祛僭 | 阶段一次弃所有手牌；对攻击范围内全部合法角色用雷杀；实际因此受伤的目标横置。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__qujian.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__qujian_remake.lua) |
| 36 | 危鸾 | 同势力杀目标含自己；可令其横置并摸1。 | [源码](pkg/fengsui_hebi/skills/fengsui_heg__weiluan.lua) / [旧版_remake](backups/checklist_20261018/fengsui_heg__weiluan_remake.lua) |
| 37 | 读心 | 明置/暗置均可触发；知己知彼不可响应并摸1；旧版翻译键已隔离，避免覆盖新版描述。 | [源码](pkg/fengsui_shiyi/skills/fengsui_toaru__heg__duxin.lua) / [旧版_remake](backups/checklist_20261018/fengsui_toaru__heg__duxin_remake.lua) |

## 全局与新增武将

- 曹氏 ID/翻译已为曹涔 `fengsui_heg__caocen`；对应头像实际文件已改名为 `image/generals/fengsui_heg__caocen.jpg`，图片字节与原头像一致。
- 所有当前技能描述中的“合璧”都附 `heg__hebi` 点击解释，包括崔芷“燃缕”、门荫；已无“合璧或变更副将”旧描述。
- 合璧有配对时执行配对副将变更并给标记；没有配对时自动变更副将，已删除有配对时主动改选普通变更的分支。
- 晋“左思左棻”：3 HP（1.5 勾玉）、双性别；研都仅自己对应武将牌明置；憧京仅自己重铸且使用精确实体牌，缺合法势力目标时自己失去体力；哀扇不限同势力，展示并按颜色/花色/牌名顺序执行。
- 群“窦武窦妙”：4 HP（2 勾玉）、双性别；拔宦可选择发动，各势力选目标后依次伤害/交牌回复；幽寰对所有受伤目标检查来源同势力。
- 拔宦现由发动者逐个选择各势力目标，按选择顺序结算，不再按座次自动排序；窄图保留原斜切版式并将两人脸部向中心微调。
- 幽寰原文写“受到伤害后”同时要求“此伤害-1”；实现使用 `DamageInflicted` 在扣体力前减伤，以保证减伤生效，描述保留用户原文。

## 验证范围

- 引擎加载成功：4330 名武将、9547 个技能，当前日志没有重复技能注册。
- 原有 22 个测试文件各 1 项通过；眷故入口另增加 23 项回归测试（连原有项共24项）通过，覆盖神毓手牌相等时不触发、弃牌数量不小于体力值、拔宦手动顺序、思疾回合结束清理及两项效果、体势回合标记归属、戚举发动者自身的次数/距离豁免、保国小势力限制和扬名统计。
- 回归测试覆盖首牌限制、矜才两分支、全场上一张牌、异势力朝华失效顺序、黜光额外阶段时机、饮冰目标独立结算、束阁平局、谙世可选后效、祛僭横置目标、幽寰减伤、憧京无目标、仇讨真实伤害、负胤失败牌处理、剑合花色、读心双时机/不可响应/摸牌/加载后描述、体势只重置拥有者、保国小势力描述和位置/名称/链接。多数分支通过真实技能回调加可控输入验证，尚未逐一完成联网实战。
- 全包 Lua 语法扫描：479 个文件，0 错误（含归档备份）；`git diff --check` 通过。
- 当前描述中未加链接的合璧：0；当前技能主 ID 重复：0；Remake 文件 ID 与文件名不一致：0。
- 45 份修改前技能备份已与 `git show HEAD:<source>` 逐字节比较一致，SHA-256 记录于 [manifest.json](backups/checklist_20261018/manifest.json)。
- 另保留3份旧描述表、64份修改前历史 Remake 原文件；未覆盖已有备份。
- 本轮全部写入均位于 `packages/fengsui`。

## 后续逐项修正（2026-10-19）

- 悲秋改用 `GeneralRevealed`，死亡清理并入已注册技能；“所念之人”固定文本。
- 碧玉的穷逋改为标准 `can_trigger/on_cost/on_use`，移除错误的山遐名称限制。
- 取声、噤誓、括户、穷逋、赏募、军巍、骤望、保国、泽誉、和乂、辟剑、诡赏、拗愎均已按最新描述同步；旧源码归档在本目录的对应 `*_remake*.lua` 文件。
- 远夷按明置武将牌数量比较；饮冰只获得诏书牌堆上的牌，不获得诏书装备牌；付授和张白易位描述已加可点击链接。
- 黜光仅使用皎宿/曜暝目标角色标记，不再记录座次。

## 分包与改名（2026-10-20）

- `fengsui_hebi` 仅保留荀粲、曹涔、崔芷、刘谌、王簌（`wangfuren`）、张白、马芝、马伦、贾午、韩寿、蒯岚、潘安 12 名武将；其余原风隋武将已移入 `fengsui_liwu`。
- `fengsui_liwu` 的注册顺序为单势力魏、蜀、吴、群、晋，之后是双势力武将，野心家杨俊最后；相关跨包配对关系已随注册位置迁移。
- 潘岳已统一改为潘安，ID 为 `fengsui_heg__panan`；立绘和阵亡语音同步改名，旧资源保存在备份目录。
- 分包前的两个 `init.lua`、旧资源均已备份；备份清单已追加到 [manifest.json](backups/checklist_20261018/manifest.json)。

## 文件

- [回归测试源码](pkg/checklist_regressions.lua)
- [首次全量测试结果](backups/checklist_20261018/test_results.json)
- [备份说明](backups/checklist_20261018/README.md)
