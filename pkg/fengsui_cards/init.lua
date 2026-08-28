local extension = Package:new("fengsui_cards", Package.CardPack)
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_cards/skills")

local taikangzhizhi = fk.CreateCard{
  name = "fengsui__taikangzhizhi",
  type = Card.TypeTrick,
  multiple_targets = true,
  skill = "fengsui__taikangzhizhi_skill",
}

-- These four faction tricks are derived card types for Zhaoshu. The leading
-- ampersand marks them as derived, and no card specs are added for them.
local rule_the_world = fk.CreateCard{
  name = "&heg_rule_the_world",
  type = Card.TypeTrick,
  skill = "rule_the_world_skill",
}

local conquering = fk.CreateCard{
  name = "&heg_conquering",
  type = Card.TypeTrick,
  skill = "heg_conquering_skill",
}

local consolidate_country = fk.CreateCard{
  name = "&heg_consolidate_country",
  type = Card.TypeTrick,
  skill = "heg_consolidate_country_skill",
}

local chaos = fk.CreateCard{
  name = "&heg_chaos",
  type = Card.TypeTrick,
  multiple_targets = true,
  skill = "heg_chaos_skill",
}

local zhaoshu = fk.CreateCard{
  name = "&heg_zhaoshu",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  skill = "heg_zhaoshu_skill",
}


extension:addCardSpec("fengsui__taikangzhizhi", Card.Heart, 8)
extension:addCardSpec("heg_zhaoshu", Card.Club, 3)
extension:addCardSpec("heg_rule_the_world", Card.Spade, 12)
extension:addCardSpec("heg_conquering", Card.Diamond, 1)
extension:addCardSpec("heg_consolidate_country", Card.Heart, 1)
extension:addCardSpec("heg_chaos", Card.Club, 12)

extension:loadCardSkels{
  taikangzhizhi,
  rule_the_world,
  conquering,
  consolidate_country,
  chaos,
  zhaoshu,
}

Fk:loadTranslationTable{
  ["fengsui__taikangzhizhi"] = "太康之治",
  [":fengsui__taikangzhizhi"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：所有与你同势力的角色<br /><b>效果</b>：目标角色将手牌摸至体力上限。晋势力角色可以额外选择一项：1.暗置变更副将（不占据次数）；2.主副将易位。",
  ["fengsui__taikangzhizhi_skill"] = "太康之治",
  ["#fengsui__taikangzhizhi_skill"] = "太康之治：令你和所有同势力角色将手牌摸至体力上限",
  ["#fengsui__taikangzhizhi-invoke"] = "太康之治：你可以额外选择一项",
  ["fengsui__taikangzhizhi_opt1"] = "暗置变更副将",
  ["fengsui__taikangzhizhi_opt2"] = "主副将易位",
}

return extension

