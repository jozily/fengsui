local extension = Package:new("mobile_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/mobile_heg/skills")

Fk:loadTranslationTable{
  ["mobile_heg"] = "国战-手杀专属",
  ["m_heg"] = "手杀",
}

local xiahoudun = General:new(extension, "m_heg__xiahoudun", "wei", 5)
xiahoudun:addSkill("ganglie")
xiahoudun:addCompanions("xiahouyuan")
Fk:loadTranslationTable{
  ["m_heg__xiahoudun"] = "夏侯惇",
  ["#m_heg__xiahoudun"] = "独眼的罗刹",
  ["illustrator:m_heg__xiahoudun"] = "KayaK",
  ["~m_heg__xiahoudun"] = "两边都看不见了……",
}

General:new(extension, "m_heg__xiahouyuan", "wei", 4):addSkill("shensu")
Fk:loadTranslationTable{
  ["m_heg__xiahouyuan"] = "夏侯渊",
  ["#m_heg__xiahouyuan"] = "疾行的猎豹",
  ["illustrator:m_heg__xiahouyuan"] = "KayaK",
  ["~m_heg__xiahouyuan"] = "竟然比我还……快……",
}

General:new(extension, "m_heg__yuejin", "wei", 4):addSkill("xiaoguo")
Fk:loadTranslationTable{
  ["m_heg__yuejin"] = "乐进",
  ["#m_heg__yuejin"] = "奋强突固",
  ["illustrator:m_heg__yuejin"] = "巴萨小马",
  ["~m_heg__yuejin"] = "箭疮发作，吾命休矣。",
}

General(extension, "m_heg__ganfuren", "shu", 3, 3, General.Female):addSkills{ "m_heg__shushen", "shenzhi" }
Fk:loadTranslationTable{
  ["m_heg__ganfuren"] = "甘夫人",
  ["#m_heg__ganfuren"] = "昭烈皇后",
  ["illustrator:m_heg__ganfuren"] = "MUMU",
  ["~m_heg__ganfuren"] = "请替我照顾好阿斗……",
}

General:new(extension, "m_heg__luxun", "wu", 3):addSkills{ "m_heg__qianxun", "m_heg__duoshi" }
Fk:loadTranslationTable{
  ["m_heg__luxun"] = "陆逊",
  ["#m_heg__luxun"] = "擎天之柱",
  ["illustrator:m_heg__luxun"] = "Zero",
  ["~m_heg__luxun"] = "还以为我已经不再年轻……",
}

General:new(extension, "m_heg__sunshangxiang", "wu", 3, 3, General.Female):addSkills{ "xiaoji", "jieyin" }
Fk:loadTranslationTable{
  ["m_heg__sunshangxiang"] = "孙尚香",
  ["#m_heg__sunshangxiang"] = "弓腰姬",
  ["illustrator:m_heg__sunshangxiang"] = "KayaK",
  ["~m_heg__sunshangxiang"] = "不！还不可以死！",
}

General:new(extension, "m_heg__panfeng", "qun", 4):addSkills{ "m_heg__kuangfu" }
Fk:loadTranslationTable{
  ["m_heg__panfeng"] = "潘凤",
  ["#m_heg__panfeng"] = "联军上将",
  ["illustrator:m_heg__panfeng"] = "明暗交界",

  ["~m_heg__panfeng"] = "潘凤又被华雄斩了。",
}

General:new(extension, "m_heg__duyu", "qun", 4):addSkills{ "m_heg__wuku", "m_heg__miewu" }
Fk:loadTranslationTable{
  ["m_heg__duyu"] = "杜预",
  ["#m_heg__duyu"] = "文成武德",
  ["illustrator:m_heg__duyu"] = "鬼画府",

  ["~m_heg__duyu"] = "洛水圆石，遂道向南，吾将以俭自完耳……",
}

General:new(extension, "m_heg__dongcheng", "qun", 4):addSkills{ "m_heg__chengzhao" }
Fk:loadTranslationTable{
  ["m_heg__dongcheng"] = "董承",
  ["#m_heg__dongcheng"] = "沥胆卫汉",
  --["illustrator:m_heg__dongcheng"] = "",

  ["~m_heg__dongcheng"] = "九泉之下，我等着你曹贼到来！",
}

return extension
