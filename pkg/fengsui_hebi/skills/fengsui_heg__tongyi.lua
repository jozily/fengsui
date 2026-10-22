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
  target_filter = function(self, player, to_select, selected)
    if #selected > 0 or not to_select:isAlive() then return false end
    if player.phase == Player.Play then
      return to_select == player
    end
    return true
  end,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("peach")
    card.skillName = tongyi.name
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
    local target = use.tos and use.tos[1]
    if target and target:isAlive() then
      room:damage {
        from = player,
        to = target,
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
  [":fengsui_heg__tongyi"] = "当你需要使用【桃】时，若你的武将牌均明置，你可以将此技能视为一张转化的【桃】使用，然后暗置此武将牌并进行判定，若结果为黑色，此牌正常结算，否则此牌目标受到来自你的一点雷属性伤害。",
  ["#fengsui_heg__tongyi"] = "通意：将此技能视为转化的【桃】使用",
}

return tongyi
