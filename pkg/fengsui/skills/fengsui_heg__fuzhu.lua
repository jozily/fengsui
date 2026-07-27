local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local fuzhu = fk.CreateSkill{
  name = "fengsui_heg__fuzhu",
}

local function getHegemonyMarkCount(player)
  local result = 0
  for _, name in ipairs({"@!!vanguard", "@!!yinyangfish", "@!!companion", "@!!wild"}) do
    result = result + player:getMark(name)
  end
  return result
end

fuzhu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuzhu.name) and data.card.is_damage_card and
      #data.tos > 0 and H.allGeneralsRevealed(player)
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = data.tos,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__fuzhu-invoke",
      skill_name = fuzhu.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    U.hideSkillGeneral(player, fuzhu.name)
    data.extraUse = true
    data:nullifyTarget(to)
    if to.dead then return end

    local choices = room:askToChoices(to, {
      choices = {"fengsui_heg__fuzhu_draw", "fengsui_heg__fuzhu_discard", "fengsui_heg__fuzhu_use"},
      min_num = 2,
      max_num = 2,
      skill_name = fuzhu.name,
      prompt = "#fengsui_heg__fuzhu-choice::" .. player.id,
      cancelable = false,
    })
    if table.contains(choices, "fengsui_heg__fuzhu_draw") then
      local count = getHegemonyMarkCount(player)
      if count > 0 then player:drawCards(count, fuzhu.name) end
    end
    if table.contains(choices, "fengsui_heg__fuzhu_discard") and not to:isNude() then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = fuzhu.name,
        prompt = "#fengsui_heg__fuzhu-discard::" .. to.id,
      })
      room:throwCard(id, fuzhu.name, to, player)
    end
    if table.contains(choices, "fengsui_heg__fuzhu_use") then
      room:addTableMark(player, "fengsui_heg__fuzhu_pending-turn", {to.id, data.card.name})
    end
  end,
})

fuzhu:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getTableMark("fengsui_heg__fuzhu_pending-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pending = player:getTableMark("fengsui_heg__fuzhu_pending-turn")
    room:setPlayerMark(player, "fengsui_heg__fuzhu_pending-turn", 0)
    for _, info in ipairs(pending) do
      local to = room:getPlayerById(info[1])
      if player:isAlive() and to and to:isAlive() then
        room:useVirtualCard(info[2], nil, player, to, fuzhu.name, true)
      end
    end
  end,
})

return fuzhu
