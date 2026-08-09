local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local wuli = fk.CreateSkill{
  name = "fengsui_heg__wuli",
  tags = { Skill.Compulsory },
}

local forbid_mark = "fengsui_heg__wuli_kingdoms-round"
local response_block_mark = "fengsui_heg__wuli_response_block"

wuli:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuli.name) and H.allGeneralsRevealed(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skill_is_deputy = U.getSkillPlace(player, wuli.name)
    if skill_is_deputy ~= nil then
      player:hideGeneral(not skill_is_deputy)
    end
    if data.from and H.getKingdom(data.from) ~= "unknown" then
      local kingdoms = player:getTableMark(forbid_mark)
      table.insertIfNeed(kingdoms, H.getKingdom(data.from))
      room:setPlayerMark(player, forbid_mark, kingdoms)
    end
  end,
})

local function updateResponseBlock(room, source, delta)
  local kingdom = H.getKingdom(source)
  for _, p in ipairs(room.alive_players) do
    if table.contains(p:getTableMark(forbid_mark), kingdom) then
      if delta > 0 then
        room:addPlayerMark(p, response_block_mark, delta)
      else
        room:removePlayerMark(p, response_block_mark, -delta)
      end
    end
  end
end

wuli:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    updateResponseBlock(player.room, player, 1)
  end,
})

wuli:addEffect(fk.CardUseFinished, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    updateResponseBlock(player.room, player, -1)
  end,
})

wuli:addEffect("prohibit", {
  global = true,
  prohibit_response = function(self, player, card)
    return player:getMark(response_block_mark) > 0
  end,
})

return wuli
