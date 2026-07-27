local extension = Package:new("fengsui_cards", Package.CardPack)
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "zhonger_heg_mode", "warlords_heg_mode", "jin_heg_mode", "tang_heg_mode" ,"new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/fengsui_cards/skills")

local taikangzhizhi = fk.CreateCard{
  name = "fengsui__taikangzhizhi",
  type = Card.TypeTrick,
  multiple_targets = true,
  skill = "fengsui__taikangzhizhi_skill",
}


extension:addCardSpec("fengsui__taikangzhizhi", Card.Heart, 8)

extension:loadCardSkels{
  taikangzhizhi,
}

Fk:loadTranslationTable{
  ["fengsui__taikangzhizhi"] = "太康之治",
  [":fengsui__taikangzhizhi"] = "出牌阶段对所有同势力角色使用，所有同势力角色将手牌摸至体力上限。晋势力角色可以额外选择一项：1.暗置变更副将（不占据次数）；2.主副将易位。",
  ["fengsui__taikangzhizhi_skill"] = "太康之治",
  ["#fengsui__taikangzhizhi_skill"] = "太康之治：令你和所有同势力角色将手牌摸至体力上限",
  ["#fengsui__taikangzhizhi-invoke"] = "太康之治：你可以额外选择一项",
  ["fengsui__taikangzhizhi_opt1"] = "暗置变更副将",
  ["fengsui__taikangzhizhi_opt2"] = "主副将易位",
}

Fk:loadTranslationTable{
  ["fengsui"] = "烽燧燎原",
  ["fengsui_cards"] = "烽燧卡牌",
  
}

return extension
