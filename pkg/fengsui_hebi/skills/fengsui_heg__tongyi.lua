local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tongyi = fk.CreateSkill {
  name = "fengsui_heg__tongyi",
}

local function resolveTongyi(player, dying)
  if not dying or dying.dead then return end
  local room = player.room
  U.hideSkillGeneral(player, tongyi.name)
  local judge = { who = player, reason = tongyi.name, pattern = "." }
  room:judge(judge)
  if judge.card and judge.card.color == Card.Black and dying:isAlive() then
    room:useVirtualCard("peach", nil, player, dying, tongyi.name, true)
  elseif dying:isAlive() then
    room:damage {
      from = player,
      to = dying,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = tongyi.name,
    }
  end
end

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
    resolveTongyi(player, data.who)
  end,
})

tongyi:addEffect("active", {
  anim_type = "defensive",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player.phase == Player.Play and player:hasSkill(self.name) and
      H.allGeneralsRevealed(player) and player:isWounded()
  end,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    resolveTongyi(effect.from, effect.from)
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__tongyi-invoke"] = "通意：是否暗置此武将牌并判定救援 %dest？",
  ["#fengsui_heg__tongyi"] = "通意：暗置此武将牌并判定，成功后对自己使用转化的【桃】",
}

return tongyi
