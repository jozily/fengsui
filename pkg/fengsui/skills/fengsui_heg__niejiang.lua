local H = require "packages.hegemony.util"

local niejiang = fk.CreateSkill{
  name = "fengsui_heg__niejiang",
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
    
    local triggered = player:getTableMark("fengsui_heg__niejiang-round")
    if table.contains(triggered, target.id) then return false end
    
    local lowest = list_lowest_hp_players(player.room)
    return table.contains(lowest, target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local triggered = player:getTableMark("fengsui_heg__niejiang-round")
    table.insert(triggered, target.id)
    room:setPlayerMark(player, "fengsui_heg__niejiang-round", triggered)
    
    local drawn_id = player:drawCards(1, niejiang.name)[1]
    if drawn_id then
      local card = Fk:getCardById(drawn_id)
      if card.trueName == "slash" then
        room:showCards({drawn_id}, player)
        room:askToUseRealCard(player, {
          pattern = {drawn_id},
          skill_name = niejiang.name,
          cancelable = false,
          prompt = "#fengsui_heg__niejiang-use",
        })
      end
    end
  end,
})

niejiang:addEffect("distance", {
  fixed_func = function(self, from, to)
    if from == to then return 0 end
    local room = from.room
    if from:hasSkill(niejiang.name) or to:hasSkill(niejiang.name) then
      local target = from:hasSkill(niejiang.name) and to or from
      local lowest = list_lowest_hp_players(room)
      if table.contains(lowest, target.id) then
        return 1
      end
    end
  end,
})
return niejiang
