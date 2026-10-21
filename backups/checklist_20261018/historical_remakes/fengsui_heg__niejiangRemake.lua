local H = require "packages.fengsui.hegemony_util"

local niejiang = fk.CreateSkill{
  name = "fengsui_heg__niejiangRemake",
  tags = {Skill.Compulsory},
}

local list_lowest_hp_players = function(room)
  local min_hp = 99
  for _, p in ipairs(room.alive_players) do
    if p.hp < min_hp then min_hp = p.hp end
  end
  local result = {}
  for _, p in ipairs(room.alive_players) do
    if p.hp == min_hp then table.insert(result, p.id) end
  end
  return result
end

niejiang:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(niejiang.name) then return false end

    local triggered = player:getTableMark("fengsui_heg__niejiangRemake-round")
    if table.contains(triggered, target.id) then return false end

    local lowest = list_lowest_hp_players(player.room)
    return table.contains(lowest, target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local triggered = player:getTableMark("fengsui_heg__niejiangRemake-round")
    table.insert(triggered, target.id)
    room:setPlayerMark(player, "fengsui_heg__niejiangRemake-round", triggered)
    player:drawCards(1, niejiang.name)
  end,
})

niejiang:addEffect("distance", {
  fixed_func = function(self, from, to)
    if from == to or not from:hasSkill(niejiang.name) then return end
    local room = Fk:currentRoom()
    if not room then return end
    local lowest = list_lowest_hp_players(room)
    if table.contains(lowest, to.id) then
      return 1
    end
  end,
})
return niejiang
