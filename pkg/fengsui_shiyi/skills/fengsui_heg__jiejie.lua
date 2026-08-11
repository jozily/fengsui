local H = require "packages.fengsui.hegemony_util"

local jiejie = fk.CreateSkill {
  name = "fengsui_heg__jiejie",
  attached_skill_name = "fengsui_heg__jiejie_active&",
}

Fk:loadTranslationTable{
  ["fengsui_heg__jiejie"] = "诚节",
  [":fengsui_heg__jiejie"] = "每名同势力角色的出牌阶段限一次，其可以将所有手牌交给你，然后你交给其等量的牌并展示之（若为你，则改为展示所有手牌）。其以此法展示的牌中，若有花色的牌数为唯一最少，其本回合使用此花色的牌无次数限制。",

  ["$fengsui_heg__jiejie1"] = "为谋大计，失小利亦无妨。",
  ["$fengsui_heg__jiejie2"] = "才思敏捷，方可识人喻事。",
}

local function refreshAttachedSkills(player)
  local room = player.room
  local owners = table.filter(room.alive_players, function(p)
    return p:hasShownSkill(jiejie.name)
  end)
  for _, p in ipairs(room.alive_players) do
    local should_attach = table.find(owners, function(owner)
      return H.compareKingdomWith(owner, p)
    end) ~= nil
    local has_attached = p:hasSkill(jiejie.attached_skill_name)
    if should_attach ~= has_attached then
      room:handleAddLoseSkills(p,
        should_attach and jiejie.attached_skill_name or "-" .. jiejie.attached_skill_name,
        nil, false, true)
    end
  end
end

local refreshSpec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    refreshAttachedSkills(player)
  end,
}

jiejie:addEffect(fk.AfterPropertyChange, refreshSpec)
jiejie:addEffect(fk.GeneralRevealed, refreshSpec)
jiejie:addEffect(fk.GeneralHidden, refreshSpec)
jiejie:addEffect(fk.Deathed, refreshSpec)
jiejie:addAcquireEffect(function(self, player) refreshAttachedSkills(player) end)
jiejie:addLoseEffect(function(self, player) refreshAttachedSkills(player) end)

return jiejie
