local H = require "packages.fengsui.hegemony_util"

local chengbi = fk.CreateSkill{
  name = "fengsui_heg__chengbi",
  attached_skill_name = "fengsui_heg__chengbi_other&",
}

local function refreshAttached(self, event, target, player, data)
  local room = player.room
  local owners = table.filter(room.alive_players, function(p)
    return p:hasShownSkill(chengbi.name)
  end)
  for _, p in ipairs(room.alive_players) do
    local enabled = table.find(owners, function(owner)
      return owner ~= p and H.compareKingdomWith(owner, p)
    end) ~= nil
    if enabled ~= p:hasSkill(chengbi.attached_skill_name) then
      room:handleAddLoseSkills(p, enabled and chengbi.attached_skill_name or "-" .. chengbi.attached_skill_name,
        nil, false, true)
    end
  end
end

for _, event in ipairs({ fk.AfterPropertyChange, fk.GeneralRevealed, fk.GeneralHidden, fk.Deathed }) do
  chengbi:addEffect(event, {
    can_refresh = function(self, event, target, player, data) return target == player end,
    on_refresh = refreshAttached,
  })
end

chengbi:addAcquireEffect(function(self, player)
  refreshAttached(self, nil, player, player, nil)
end)

chengbi:addLoseEffect(function(self, player)
  refreshAttached(self, nil, player, player, nil)
end)

Fk:loadTranslationTable{
  ["fengsui_heg__chengbi"] = "承辟",
  [":fengsui_heg__chengbi"] = "同势力角色的每回合限一次，其可弃置你与其各一张牌，视为使用一张与任意一张弃置牌合法目标相同的基本牌（计算目标时视为你使用）。",
  ["fengsui_heg__chengbi_other&"] = "承辟",
  [":fengsui_heg__chengbi_other&"] = "每回合限一次，你可弃置你与一名拥有“承辟”的同势力角色各一张牌，令其视为使用一张基本牌。",
  ["#fengsui_heg__chengbi-other"] = "承辟：选择一名同势力角色，弃置你与其各一张牌",
  ["#fengsui_heg__chengbi-discard"] = "承辟：弃置 %dest 的一张牌",
  ["#fengsui_heg__chengbi-use"] = "承辟：请选择一种基本牌，令 %dest 视为使用",
  ["@fengsui_heg__chengbi-turn"] = "承辟",
}

return chengbi
