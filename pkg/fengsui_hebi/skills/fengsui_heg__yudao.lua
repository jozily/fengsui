local H = require "packages.fengsui.hegemony_util"

local yudao = fk.CreateSkill {
  name = "fengsui_heg__yudao",
}

local function arrangeXunxun(player)
  if player.dead then return end
  local room = player.room
  local ret = room:askToArrangeCards(player, {
    skill_name = "hs__xunxun",
    card_map = { room:getNCards(4), "Bottom", "Top" },
    prompt = "#xunxun",
    free_arrange = true,
    max_limit = { 4, 2 },
    min_limit = { 0, 2 },
  })
  local top, bottom = ret[2], ret[1]
  for i = #top, 1, -1 do
    table.removeOne(room.draw_pile, top[i])
    table.insert(room.draw_pile, 1, top[i])
  end
  for _, id in ipairs(bottom) do
    table.removeOne(room.draw_pile, id)
    table.insert(room.draw_pile, id)
  end
  room:sendLog { type = "#GuanxingResult", from = player.id, arg = #top, arg2 = #bottom }
end

local function participants(event, player, data)
  if event == fk.Damage then
    return player, data.to
  end
  return data.from, player
end

for _, event in ipairs({ fk.Damage, fk.Damaged }) do
  yudao:addEffect(event, {
    anim_type = "support",
    can_trigger = function(self, _, target, player, data)
      if target ~= player or not player:hasSkill(self.name) or
        player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 or
        not data or data.damageType == fk.NormalDamage then
        return false
      end
      local source, victim = participants(event, player, data)
      return (source and source:isAlive() and H.compareKingdomWith(player, source)) or
        (victim and victim:isAlive() and H.compareKingdomWith(player, victim))
    end,
    on_cost = function(self, event, target, player, data)
      return player.room:askToSkillInvoke(player, {
        skill_name = self.name,
        prompt = "#fengsui_heg__yudao-invoke",
      })
    end,
    on_use = function(self, event, target, player, data)
      local source, victim = participants(event, player, data)
      if source and source:isAlive() and H.compareKingdomWith(player, source) then
        H.askToHebiOrTransform(player.room, source, self.name, false)
      end
      if victim and victim:isAlive() and H.compareKingdomWith(player, victim) then
        arrangeXunxun(victim)
      end
    end,
  })
end

Fk:loadTranslationTable {
  ["#fengsui_heg__yudao-invoke"] = "熨道：你可以发动此技能",
}

return yudao
