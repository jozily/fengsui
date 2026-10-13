local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local s = fk.CreateSkill { name = "fengsui_heg__shenyu_track" }
s:addEffect(fk.AfterCardsMove, { global = true,
  can_refresh = function(self, _, target, player, data)
    return player and U.hasGeneralName(player, "fengsui_heg__weijie") and player:hasShownSkill("fengsui_heg__shenyu") and data and table.find(data, function(m)
      return m.from == player.room.current and m.moveReason == fk.ReasonDiscard and m.toArea == Card.DiscardPile and m.moveInfo and #m.moveInfo > 0
    end) ~= nil
  end,
  on_refresh = function(self, _, target, player, data)
    local c, n = player.room.current, 0
    if not c then return end
    for _, m in ipairs(data) do
      if m.from == c and m.moveReason == fk.ReasonDiscard and m.toArea == Card.DiscardPile and m.moveInfo then
        n = n + #m.moveInfo
      end
    end
    if n > 0 then player.room:addPlayerMark(c, "fengsui_heg__shenyu-discard", n) end
  end,
})
return s
