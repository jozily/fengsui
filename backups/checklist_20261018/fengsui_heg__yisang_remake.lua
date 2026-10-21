local H = require "packages.fengsui.hegemony_util"
local yisang = fk.CreateSkill { name = "fengsui_heg__yisang" }

-- 记录本回合场上上一张使用或打出的牌颜色。
yisang:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, _, target, _, data)
    return target and target.room.current == target and data.card ~= nil
  end,
  on_refresh = function(self, _, target, _, data)
    target.room:setPlayerMark(target, "fengsui_heg__yisang_last_color-turn", data.card.color)
  end,
})
yisang:addEffect(fk.CardResponding, {
  global = true,
  mute = true,
  can_refresh = function(self, _, target, _, data)
    return target and target.room.current == target and data.card ~= nil
  end,
  on_refresh = function(self, _, target, _, data)
    target.room:setPlayerMark(target, "fengsui_heg__yisang_last_color-turn", data.card.color)
  end,
})

yisang:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  can_trigger = function(self, _, target, player, data)
    local recipient = data.to
    if not target or not recipient or not player:hasSkill(self.name) or
      not H.compareKingdomWith(recipient, player) or not data.card then return false end
    local last = target:getMark("fengsui_heg__yisang_last_color-turn")
    return last ~= 0 and last == data.card.color
  end,
  on_cost = function(self, event, target, player, data)
    local recipient = data.to
    if player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__yisang-invoke::" .. recipient.id,
    }) then
      event:setCostData(self, { to = recipient })
      return true
    end
  end,
  on_use = function(self, event, _, player)
    local recipient = event:getCostData(self).to
    if recipient:isNude() then return end
    local ids = player.room:askToChooseCards(recipient, {
      target = recipient, flag = "he", min = 1, max = 1,
      skill_name = self.name, prompt = "#fengsui_heg__yisang-recast",
    })
    if #ids > 0 then player.room:recastCard(ids, recipient, self.name) end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__yisang-recast"] = "诒桑：选择一张牌重铸",
}

return yisang
