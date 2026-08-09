local H = require "packages.fengsui.hegemony_util"

local xuanhe = fk.CreateSkill{
  name = "fengsui_heg__xuanhe",
  tags = { Skill.Compulsory, Skill.MainPlace },
}

local used_mark = "fengsui_heg__xuanhe_used-turn"

xuanhe:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, used_mark, 1)
  end,
})

xuanhe:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhe.name) and
      player:usedSkillTimes(xuanhe.name, Player.HistoryTurn) == 0 and #data.tos > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    for _, to in ipairs(data.tos) do
      if to:isAlive() then
        player.room:setPlayerMark(to, "fengsui_heg__xuanhe_type-turn", data.card.type)
      end
    end
  end,
})

local function clearTypeMark(event, target, player, data)
  return target == player and player:getMark("fengsui_heg__xuanhe_type-turn") > 0 and
    data.card.type ~= player:getMark("fengsui_heg__xuanhe_type-turn")
end

xuanhe:addEffect(fk.PreCardUse, {
  global = true,
  can_refresh = clearTypeMark,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__xuanhe_type-turn", 0)
  end,
})

xuanhe:addEffect(fk.CardResponding, {
  global = true,
  can_refresh = clearTypeMark,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__xuanhe_type-turn", 0)
  end,
})

xuanhe:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    return player:getMark("fengsui_heg__xuanhe_type-turn") == card.type
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("fengsui_heg__xuanhe_type-turn") == card.type
  end,
  is_prohibited = function(self, from, to, card)
    if not (from and to and card and from ~= to and to:hasSkill(xuanhe.name) and
      H.compareKingdomWith(from, to)) then return false end
    return from:getMark(used_mark) == 0
  end,
})

return xuanhe
