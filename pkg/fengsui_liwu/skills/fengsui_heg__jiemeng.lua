local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_liwu.util"

local jiemeng = fk.CreateSkill{
  name = "fengsui_heg__jiemeng",
}

local function availableTargets(player)
  return table.filter(player.room.alive_players, function(p)
    return H.getKingdom(p) ~= "unknown" and player:canUseTo(Fk:cloneCard("overbearing"), p)
  end)
end

jiemeng:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__jiemeng_using") == 0 and
      player:hasShownSkill(jiemeng.name) and #availableTargets(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(availableTargets(player), Util.IdMapper)
    local use = player.room:askToUseVirtualCard(player, {
      name = "overbearing",
      skill_name = jiemeng.name,
      prompt = "#fengsui_heg__jiemeng",
      cancelable = true,
      skip = true,
      extra_data = { exclusive_targets = targets },
    })
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self)
    local selfTarget = use.tos and use.tos[1] == player
    room:setPlayerMark(player, "fengsui_heg__jiemeng_using", 1)
    room:setPlayerMark(player, "fengsui_heg__jiemeng_hit", 0)
    if selfTarget and H.allGeneralsRevealed(player) then
      U.hideSkillGeneral(player, jiemeng.name)
    end
    room:useCard(use)
    room:setPlayerMark(player, "fengsui_heg__jiemeng_using", 0)
    if not selfTarget and player:getMark("fengsui_heg__jiemeng_hit") > 0 and H.allGeneralsRevealed(player) then
      U.hideSkillGeneral(player, jiemeng.name)
    end
    room:setPlayerMark(player, "fengsui_heg__jiemeng_hit", 0)
  end,
})

jiemeng:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("fengsui_heg__jiemeng_using") > 0 and data.from == player and
      data.card and data.card.name == "overbearing"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__jiemeng_hit", 1)
  end,
})

return jiemeng
