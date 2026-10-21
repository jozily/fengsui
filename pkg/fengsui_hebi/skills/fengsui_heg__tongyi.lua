local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tongyi = fk.CreateSkill {
  name = "fengsui_heg__tongyi",
}

tongyi:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self.name) and
      H.allGeneralsRevealed(player) and data and data.who and data.who:isAlive()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__tongyi-invoke::" .. data.who.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dying = data.who
    U.hideSkillGeneral(player, self.name)
    local judge = { who = player, reason = self.name, pattern = "." }
    room:judge(judge)
    if judge.card and judge.card.color == Card.Black and dying:isAlive() then
      room:useVirtualCard("peach", nil, player, dying, self.name, true)
    elseif dying:isAlive() then
      room:damage {
        from = player,
        to = dying,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__tongyi-invoke"] = "通意：你可以暗置此武将牌并判定救援 %dest",
}

return tongyi
