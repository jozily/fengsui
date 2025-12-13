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

local zhonghui = General:new(extension, "ol_heg__zhonghui", "wei", 4)
zhonghui.mainMaxHpAdjustedValue = -1
zhonghui:addSkills{ "ol_heg__quanji", "ol_heg__paiyi", "ol_heg__yaopan" }
Fk:loadTranslationTable{
  ["ol_heg__zhonghui"] = "钟会",
  ["#ol_heg__zhonghui"] = "桀骜的野心家",
  ["illustrator:ol_heg__zhonghui"] = "官方",

  ["~ol_heg__zhonghui"] = "伯约，让你失望了。",
}

local wuyi = General:new(extension, "ol_heg__wuyi", "shu", 4)
wuyi:addCompanions("hs__weiyan")
wuyi:addSkills{ "ol_heg__benxi","ol_heg__zhuanzheng"}
Fk:loadTranslationTable{
  ["ol_heg__wuyi"] = "吴懿",
  ["#ol_heg__wuyi"] = "建兴鞍辔",
  ["illustrator:ol_heg__wuyi"] = "官方",

  ["~ol_heg__wuyi"] = "奔波已疲，难以，再战。",
}

local chengpu = General:new(extension, "ol_heg__chengpu", "wu", 4)
chengpu:addCompanions{ "hs__zhouyu","hs__huanggai" }
chengpu:addSkills{ "ol_heg__daohuo","ol_heg__chunlao" }
Fk:loadTranslationTable{
  ["ol_heg__chengpu"] = "程普",
  ["#ol_heg__chengpu"] = "三朝虎臣",

  ["~ol_heg__chengpu"] = "没，没有酒了……",
}

return extension