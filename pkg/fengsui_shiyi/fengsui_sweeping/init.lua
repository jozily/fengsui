return function(extension)
extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_shiyi/fengsui_sweeping/skills")

Fk:appendKingdomMap("fengsui_sweeping", { "wei", "shu", "wu", "qun", "jin" })

local qinshi = General:new(extension, "fengsui_limited_heg__qinshimd", "wild", 3)
qinshi:addSkills { "fengsui_limited_heg__yangzhi", "fengsui_limited_heg__zhenming", "fengsui_limited_heg__yangqin" }
local zhanjiang = General:new(extension, "fengsui_limited_heg__zhanjiangmd", "fengsui_neutralall", 4)
zhanjiang:addSkills { "fengsui_limited_heg__duoshou", "fengsui_limited_heg__yanzhen" }
local xunyu = General:new(extension, "fengsui_limited_heg__xunyu", "fengsui_neutralall", 4)
xunyu:addCompanions("hs__xunyu")
xunyu:addSkills { "fengsui_limited_heg__wangzuo", "fengsui_limited_heg__shendu" }

local no1 = General:new(extension, "fengsui_limited_heg__sweeperno1", "fengsui_sweeping", 3, 3, General.Female)
no1:addSkills { "fengsui_limited_heg__sweeping", "fengsui_limited_heg__ailiu", "fengsui_limited_heg__tanghou" }
local no2 = General:new(extension, "fengsui_limited_heg__sweeperno2", "fengsui_sweeping", 4, 4, General.Female)
no2:addSkills { "fengsui_limited_heg__sweeping", "fengsui_limited_heg__meimo" }
no1:addCompanions(no2.name)
no2:addCompanions(no1.name)

Fk:loadTranslationTable {
  ["fengsui_sweeping"] = "扫荡者",
  ["fengsui_limited_heg__sweeperno1"] = "时空",
  ["fengsui_limited_heg__sweeperno2"] = "恩泽",
  ["fengsui_limited_heg__qinshimd"] = "绝命琴师",
  ["fengsui_limited_heg__zhanjiangmd"] = "斩将者",
  ["fengsui_limited_heg__xunyu"] = "荀彧",
  ["designer:fengsui_limited_heg__sweeperno1"] = "Mayday",
  ["designer:fengsui_limited_heg__sweeperno2"] = "Mayday",
  ["designer:fengsui_limited_heg__qinshimd"] = "Mayday",
  ["designer:fengsui_limited_heg__zhanjiangmd"] = "Mayday",
  ["designer:fengsui_limited_heg__xunyu"] = "Mayday",
}

end
