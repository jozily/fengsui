local H = require "packages.fengsui.hegemony_util"

local piruan = fk.CreateSkill{name = "fengsui_limited_heg__piruan", tags = { Skill.Compulsory }}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__piruan"] = "疲软",
  [":fengsui_limited_heg__piruan"] = "锁定技，当你成为一张锦囊牌的目标后，若你的武将牌均明置，你暗置此武将牌。",
}

piruan:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(piruan.name) and data.card.type == Card.TypeTrick and
      H.allGeneralsRevealed(player)
  end,
  on_use = function(self, event, target, player, data)
    H.hideBySkillName(player, piruan.name)
  end,
})

return piruan
