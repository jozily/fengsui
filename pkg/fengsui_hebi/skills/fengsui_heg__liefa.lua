local H = require "packages.fengsui.hegemony_util"

local liefa = fk.CreateSkill{
  name = "fengsui_heg__liefa",
  related_skills = {"heg__bingxin", "niaoxiang"},
}

liefa:addEffect("arraysummon", { array_type = "formation" })

local function formsSiege(player)
  for _, victim in ipairs(player.room.alive_players) do
    if victim ~= player and H.inSiegeRelation(player, player, victim) then return true end
  end
  return false
end

local function refreshBorrowed(room, owner)
  local formation = H.inFormationRelation(owner, owner)
  for _, p in ipairs(room.alive_players) do
    local should = p ~= owner and formation and H.inFormationRelation(owner, p)
    local mark = "fengsui_heg__liefa_bingxin_" .. owner.id
    if should and p:getMark(mark) == 0 then
      if not p:hasSkill("heg__bingxin") then room:handleAddLoseSkills(p, "heg__bingxin") end
      room:setPlayerMark(p, mark, 1)
    elseif not should and p:getMark(mark) > 0 then
      room:setPlayerMark(p, mark, 0)
      local needed = table.find(room.alive_players, function(other)
        return other ~= owner and p:getMark("fengsui_heg__liefa_bingxin_" .. other.id) > 0
      end)
      if not needed and not H.inGeneralSkills(p, "heg__bingxin") then
        room:handleAddLoseSkills(p, "-heg__bingxin")
      end
    end
  end

  local siege = formsSiege(owner)
  if siege and owner:getMark("fengsui_heg__liefa_niaoxiang") == 0 then
    if not owner:hasSkill("niaoxiang") then room:handleAddLoseSkills(owner, "niaoxiang") end
    room:setPlayerMark(owner, "fengsui_heg__liefa_niaoxiang", 1)
  elseif not siege and owner:getMark("fengsui_heg__liefa_niaoxiang") > 0 then
    room:setPlayerMark(owner, "fengsui_heg__liefa_niaoxiang", 0)
    if not H.inGeneralSkills(owner, "niaoxiang") then room:handleAddLoseSkills(owner, "-niaoxiang") end
  end
end

local refresh = {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(liefa.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    refreshBorrowed(player.room, player)
  end,
}

liefa:addEffect(fk.TurnStart, refresh)
liefa:addEffect(fk.GeneralRevealed, refresh)
liefa:addEffect(fk.GeneralHidden, refresh)
liefa:addEffect(fk.AfterPropertyChange, refresh)

liefa:addEffect(fk.GeneralRevealed, {
  global = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not target or not player:hasSkill(liefa.name) or not H.compareKingdomWith(target, player) then return false end
    return H.inFormationRelation(player, player) == formsSiege(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = liefa.name, prompt = "#fengsui_heg__liefa-transform::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    H.transformGeneral(player.room, target, false, false)
  end,
})

return liefa
