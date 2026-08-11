local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local fuzhu = fk.CreateSkill{
  name = "fengsui_heg__fuzhuRemake",
}

local pending_mark = "fengsui_heg__fuzhuRemake_pending"

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
    return target == player and player:hasSkill(fuzhu.name) and data.card and
      data.card.is_damage_card and #data.tos > 0 and H.allGeneralsRevealed(player) and
      not (data.extra_data or {}).fengsui_heg__fuzhuRemake_delayed
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = data.tos,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__fuzhuRemake-invoke",
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
    data.nullifiedTargets = data.nullifiedTargets or {}
    table.insertIfNeed(data.nullifiedTargets, to)
    if to.dead then return end

    local mark_count = getHegemonyMarkCount(player)
    local choices = {"fengsui_heg__fuzhuRemake_use"}
    if mark_count == 0 or #to:getCardIds("he") >= mark_count then
      table.insert(choices, 1, "fengsui_heg__fuzhuRemake_discard")
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = fuzhu.name,
      prompt = "#fengsui_heg__fuzhuRemake-choice::" .. player.id .. ":" .. mark_count,
      cancelable = false,
    })
    if choice == "fengsui_heg__fuzhuRemake_discard" then
      if mark_count > 0 then
        room:askToDiscard(to, {
          min_num = mark_count,
          max_num = mark_count,
          include_equip = true,
          skill_name = fuzhu.name,
          prompt = "#fengsui_heg__fuzhuRemake-discard:::" .. mark_count,
          cancelable = false,
        })
      end
    else
      room:addTableMark(player, pending_mark, {to.id, data.card.name})
    end
  end,
})

fuzhu:addEffect(fk.TurnEnd, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getTableMark(pending_mark) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pending = player:getTableMark(pending_mark)
    room:setPlayerMark(player, pending_mark, 0)
    for _, info in ipairs(pending) do
      local to = room:getPlayerById(info[1])
      if player:isAlive() and to and to:isAlive() then
        local card = Fk:cloneCard(info[2])
        card.skillName = fuzhu.name
        if player:canUseTo(card, to, {bypass_times = true, bypass_distances = true}) then
          room:useCard{
            from = player,
            tos = {to},
            card = card,
            extraUse = true,
            extra_data = {
              bypass_times = true,
              bypass_distances = true,
              fengsui_heg__fuzhuRemake_delayed = true,
            },
          }
        end
      end
    end
  end,
})

return fuzhu
