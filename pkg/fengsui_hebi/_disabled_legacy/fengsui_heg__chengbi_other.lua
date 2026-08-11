local H = require "packages.fengsui.hegemony_util"
local U = require "packages.utility.utility"

local chengbi_other = fk.CreateSkill{
  name = "fengsui_heg__chengbi_other&",
}

chengbi_other:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__chengbi-other",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@fengsui_heg__chengbi-turn") == 0 and not player:isNude()
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isNude() and
      to_select:hasShownSkill("fengsui_heg__chengbi") and H.compareKingdomWith(to_select, player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local owner = effect.tos[1]
    room:setPlayerMark(player, "@fengsui_heg__chengbi-turn", 1)

    local own = room:askToDiscard(player, {
      min_num = 1, max_num = 1, include_equip = true, cancelable = false,
      skill_name = chengbi_other.name,
    })
    if #own == 0 or owner.dead or owner:isNude() then return end
    local owner_card = room:askToChooseCard(player, {
      target = owner, flag = "he", skill_name = chengbi_other.name,
      prompt = "#fengsui_heg__chengbi-discard::" .. owner.id,
    })
    room:throwCard(owner_card, chengbi_other.name, owner, player)
    if owner.dead then return end

    local names = owner:getViewAsCardNames(chengbi_other.name, Fk:getAllCardNames("b"), nil, nil,
      { bypass_times = true })
    if #names == 0 then return end
    local name = U.askForChooseCardNames(room, player, names, 1, 1, chengbi_other.name,
      "#fengsui_heg__chengbi-use::" .. owner.id)[1]
    if name then
      room:askToUseVirtualCard(owner, {
        name = name,
        skill_name = "fengsui_heg__chengbi",
        prompt = "#fengsui_heg__chengbi-use::" .. owner.id,
        extra_data = { bypass_times = true, extraUse = true },
        cancelable = true,
      })
    end
  end,
})

return chengbi_other
