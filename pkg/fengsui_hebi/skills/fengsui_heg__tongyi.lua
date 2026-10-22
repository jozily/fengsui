local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tongyi = fk.CreateSkill {
  name = "fengsui_heg__tongyi",
}

tongyi:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "peach",
  prompt = "#fengsui_heg__tongyi",
  card_filter = function() return false end,
  feasible = function(self, player, selected)
    return #selected > 0
  end,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("peach")
    card.skillName = tongyi.name
    card:setVSPattern(tongyi.name, player)
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    U.hideSkillGeneral(player, tongyi.name)
    local judge = { who = player, reason = tongyi.name, pattern = "." }
    room:judge(judge)
    if judge.card and judge.card.color == Card.Black then
      return
    end
    if player:isAlive() then
      room:damage {
        to = player,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = tongyi.name,
      }
    end
    return tongyi.name
  end,
  enabled_at_play = function(self, player)
    return H.allGeneralsRevealed(player) and player:isWounded()
  end,
  enabled_at_response = function(self, player, response)
    return not response and H.allGeneralsRevealed(player)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__tongyi"] = "通意",
  [":fengsui_heg__tongyi"] = "当你需要使用【桃】时，若你的武将牌均明置，你可暗置此武将牌并进行一次判定，若结果为黑色，你视为使用之，否则你受到一点无来源的雷属性伤害。",
  ["#fengsui_heg__tongyi"] = "通意：将此技能视为转化的【桃】使用",
}

return tongyi
