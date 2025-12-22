local extension = Package:new("online_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/online_heg/skills")

Fk:loadTranslationTable{
  ["online_heg"] = "国战-OL专属",
  ["ol_heg"] = "OL",
  ["#heg_swap_deputy"] = "%from 与 %to 交换了副将",
  ["heg__yiwei"] = "易位：发起武将易位后，若目标角色选择执行，则易位双方交换对应武将。<br>"..
  "一名角色只能对相同势力的其他角色发起武将易位。易位武将不会影响你的体力上限，也不会获得珠联璧合、阴阳鱼标记。"..
  "易位武将不会移除武将牌上的牌，如“屯田”等，也不会影响技能状态，比如限定技、每回合限一次、断肠、铁骑等。",
}

local generals = {}  --绕过变量上限的东西

General:new(extension, "ol_heg__zhangchunhua", "jin", 3, 3, General.Female):addSkills{ "ol__huishi", "qingleng" }
Fk:loadTranslationTable{
  ["ol_heg__zhangchunhua"] = "张春华",
  ["#ol_heg__zhangchunhua"] = "宣穆皇后",
  ["illustrator:ol_heg__zhangchunhua"] = "biou09",

  ["~ol_heg__zhangchunhua"] = "冷眸残情，孤苦为一人。",
}

generals.ol_heg__simayi = General:new(extension, "ol_heg__simayi", "jin", 3)
generals.ol_heg__simayi:addCompanions({ "ol_heg__zhangchunhua", "ol_heg__shibao" })
generals.ol_heg__simayi:addSkills { "yingshis", "xiongzhi", "quanbian" }
Fk:loadTranslationTable{
  ["ol_heg__simayi"] = "司马懿",
  ["#ol_heg__simayi"] = "通权达变",
  ["illustrator:ol_heg__simayi"] = "biou09",

  ["~ol_heg__simayi"] = "虎入骷冢，司马难兴。",
}

General:new(extension, "ol_heg__yanghuiyu", "jin", 3, 3, General.Female):addSkills{ "ciwei", "caiyuan" }
Fk:loadTranslationTable{
  ["ol_heg__yanghuiyu"] = "羊徽瑜",
  ["#ol_heg__yanghuiyu"] = "景献皇后",
  ["illustrator:ol_heg__yanghuiyu"] = "depp",

  ["~ol_heg__yanghuiyu"] = "韶华易老，佳容不再……",
}

generals.ol_heg__simashi = General:new(extension, "ol_heg__simashi", "jin", 3)
generals.ol_heg__simashi:addCompanions({ "ol_heg__xiahouhui", "ol_heg__yanghuiyu" })
generals.ol_heg__simashi:addSkills{ "yimie", "tairan" }
Fk:loadTranslationTable{
  ["ol_heg__simashi"] = "司马师",
  ["#ol_heg__simashi"] = "晋景王",
  ["illustrator:ol_heg__simashi"] = "凝聚永恒",

  ["~ol_heg__simashi"] = "子上，这是为兄给你打下的江山……",
}

General:new(extension, "ol_heg__xiahouhui", "jin", 3, 3, General.Female):addSkills{ "yishi", "shidu" }
Fk:loadTranslationTable{
  ["ol_heg__xiahouhui"] = "夏侯徽",
  ["#ol_heg__xiahouhui"] = "景怀皇后",
  ["illustrator:ol_heg__xiahouhui"] = "凝聚永恒",

  ["~ol_heg__xiahouhui"] = "夫君，你怎么对我如此狠心……",
}

generals.ol_heg__simazhao = General:new(extension, "ol_heg__simazhao", "jin", 3)
generals.ol_heg__simazhao:addCompanions("ol_heg__wangyuanji")
generals.ol_heg__simazhao:addSkills { "choufa", "zhaoran" }
Fk:loadTranslationTable{
  ["ol_heg__simazhao"] = "司马昭",
  ["#ol_heg__simazhao"] = "晋文帝",
  ["illustrator:ol_heg__simazhao"] = "凝聚永恒",

  ["~ol_heg__simazhao"] = "司马三代，一梦成空……",
}

General:new(extension, "ol_heg__wangyuanji", "jin", 3, 3, General.Female):addSkills{ "yanxi" }
Fk:loadTranslationTable{
  ["ol_heg__wangyuanji"] = "王元姬",
  ["#ol_heg__wangyuanji"] = "文明皇后",
  ["illustrator:ol_heg__wangyuanji"] = "凝聚永恒",

  ["~ol_heg__wangyuanji"] = "祖父已逝，哀凄悲戚。",
}

generals.ol_heg__duyu = General:new(extension, "ol_heg__duyu", "jin", 4)
generals.ol_heg__duyu:addSkills{ "ol_heg__sanchen" }
generals.ol_heg__duyu:addRelatedSkills{ "pozhu" }
Fk:loadTranslationTable{
  ["ol_heg__duyu"] = "杜预",
  ["#ol_heg__duyu"] = "文成武德",
  ["illustrator:ol_heg__duyu"] = "一串糖葫芦",

  ["$pozhu_ol_heg__duyu1"] = "时机已至，当奋破竹之势，一举得胜！",
  ["$pozhu_ol_heg__duyu2"] = "兵威已振，应如以刀劈竹，迎刃而解！",
  ["~ol_heg__duyu"] = "佳人已去，幽梦犹存。",
}

General:new(extension, "ol_heg__shibao", "jin", 4):addSkills{ "ol_heg__zhuosheng" }
Fk:loadTranslationTable{
  ["ol_heg__shibao"] = "石苞",
  ["#ol_heg__shibao"] = "乐陵郡公",
  ["illustrator:ol_heg__shibao"] = "凡果",

  ["~ol_heg__shibao"] = "寒门出身，难以擢升。",
}

General:new(extension, "ol_heg__simazhou", "jin", 4):addSkills{ "ol_heg__caiwang", "naxiang" }
Fk:loadTranslationTable{
  ["ol_heg__simazhou"] = "司马伷",
  ["#ol_heg__simazhou"] = "琅琊武王",
  ["illustrator:ol_heg__simazhou"] = "西国红云",

  ["~ol_heg__simazhou"] = "恩赐重物，病身难消受……",
}

generals.ol_heg__zhanghuyuechen = General:new(extension, "ol_heg__zhanghuyuechen", "jin", 4)
generals.ol_heg__zhanghuyuechen:addSkills{ "ol_heg__xijue" }
generals.ol_heg__zhanghuyuechen:addRelatedSkills{ "ex__tuxi", "nos__xiaoguo" }
Fk:loadTranslationTable{
  ["ol_heg__zhanghuyuechen"] = "张虎乐綝",
  ["#ol_heg__zhanghuyuechen"] = "不辱门庭",
  ["illustrator:ol_heg__zhanghuyuechen"] = "妙喵",

  ["$ex__tuxi_ol_heg__zhanghuyuechen1"] = "动如霹雳，威震宵小！",
  ["$ex__tuxi_ol_heg__zhanghuyuechen2"] = "行略如风，摧枯拉朽！",
  ["$nos__xiaoguo_ol_heg__zhanghuyuechen1"] = "大丈夫生于世，当沙场效忠！",
  ["$nos__xiaoguo_ol_heg__zhanghuyuechen2"] = "骁勇善战，刚毅果断！",
  ["~ol_heg__zhanghuyuechen"] = "儿有辱……父亲威名……",
}

generals.ol_heg__zhonghui = General:new(extension, "ol_heg__zhonghui", "wei", 4)
generals.ol_heg__zhonghui.mainMaxHpAdjustedValue = -1
generals.ol_heg__zhonghui:addSkills{ "ol_heg__quanji", "ol_heg__paiyi", "ol_heg__yaopan" }
Fk:loadTranslationTable{
  ["ol_heg__zhonghui"] = "钟会",
  ["#ol_heg__zhonghui"] = "桀骜的野心家",
  ["illustrator:ol_heg__zhonghui"] = "官方",

  ["~ol_heg__zhonghui"] = "伯约，让你失望了。",
}

generals.ol_heg__wuyi = General:new(extension, "ol_heg__wuyi", "shu", 4)
generals.ol_heg__wuyi:addCompanions("hs__weiyan")
generals.ol_heg__wuyi:addSkills{ "ol_heg__benxi","ol_heg__zhuanzheng"}
Fk:loadTranslationTable{
  ["ol_heg__wuyi"] = "吴懿",
  ["#ol_heg__wuyi"] = "建兴鞍辔",
  ["illustrator:ol_heg__wuyi"] = "官方",

  ["~ol_heg__wuyi"] = "奔波已疲，难以，再战。",
}

generals.ol_heg__chengpu = General:new(extension, "ol_heg__chengpu", "wu", 4)
generals.ol_heg__chengpu:addCompanions{ "hs__zhouyu","hs__huanggai" }
generals.ol_heg__chengpu:addSkills{ "ol_heg__daohuo","ol_heg__chunlao" }
Fk:loadTranslationTable{
  ["ol_heg__chengpu"] = "程普",
  ["#ol_heg__chengpu"] = "三朝虎臣",

  ["~ol_heg__chengpu"] = "没，没有酒了……",
}

return extension