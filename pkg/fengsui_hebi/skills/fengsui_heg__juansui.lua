local H = require "packages.fengsui.hegemony_util"

local juansui = fk.CreateSkill{
  name = "fengsui_heg__juansui",
  tags = { Skill.Compulsory },
}

juansui:addEffect(fk.HpChanged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juansui.name) and player.hp == 1 and data.old ~= 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, juansui.name)
    player:reset()

    local used = player:getTableMark("fengsui_heg__juansui_used_tricks")
    local tricks = {}
    for _, name in ipairs(require("packages.fengsui.pkg.fengsui_hebi.util").getNationalCardNames({"trick"})) do
      local card = Fk:cloneCard(name)
      if not table.contains(used, name) then
        table.insertIfNeed(tricks, name)
      end
    end

    local current = room.current
    if #tricks > 0 and current then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return H.compareKingdomWith(p, current)
      end), Util.IdMapper)
      local use = room:askToUseVirtualCard(player, {
        name = tricks,
        skill_name = juansui.name,
        prompt = "#fengsui_heg__juansui-use",
        cancelable = false,
        extra_data = {exclusive_targets = targets},
      })
      if use then
        table.insertIfNeed(used, use.card.name)
        room:setPlayerMark(player, "fengsui_heg__juansui_used_tricks", used)
      end
    end
  end,
})

return juansui
