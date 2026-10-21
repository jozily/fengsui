local H = require "packages.fengsui.hegemony_util"
local yisang = fk.CreateSkill {name = "fengsui_heg__yisang"}
local lastMark = "fengsui_heg__yisang_last-turn"
for _, timing in ipairs({fk.PreCardUse, fk.CardResponding}) do
  yisang:addEffect(timing, {
    global = true, mute = true,
    can_refresh = function(self, _, target, _, data)
      return target and target.room.current and data.card and not (data.extra_data and data.extra_data.yisang_recorded)
    end,
    on_refresh = function(self, _, target, _, data)
      local room = target.room
      data.extra_data = data.extra_data or {}
      data.extra_data.yisang_recorded = true
      local previous = room.current:getTableMark(lastMark)
      data.extra_data.yisang_previous_color = previous.color
      room:setPlayerMark(room.current, lastMark, {color = data.card.color})
    end,
  })
end
yisang:addEffect(fk.TargetConfirmed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local extra = data.use.extra_data
    return player:hasSkill(yisang.name) and H.compareKingdomWith(target, player) and not target:isNude() and
      extra and extra.yisang_previous_color ~= nil and extra.yisang_previous_color == data.card.color
  end,
  on_cost = function(self, event, target, player)
    local cards = player.room:askToCards(target, {min_num = 1, max_num = 1, include_equip = true,
      skill_name = yisang.name, prompt = "#fengsui_heg__yisang-recast", cancelable = true})
    if #cards > 0 then event:setCostData(self, cards); return true end
  end,
  on_use = function(self, event, target, player)
    player.room:recastCard(event:getCostData(self), target, yisang.name)
  end,
})
Fk:loadTranslationTable{["#fengsui_heg__yisang-recast"] = "诒桑：你可以重铸一张牌"}
return yisang
