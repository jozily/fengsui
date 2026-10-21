local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local Util = require "packages.utility.utility"

local yuchen = fk.CreateSkill { name = "fengsui_heg__yuchen" }

local function equalYinYang(player)
  local main = Fk.generals[H.getActualGeneral(player, false)]
  local deputy = Fk.generals[H.getActualGeneral(player, true)]
  if not main or not deputy then return false end
  return (main.maxHp + (main.mainMaxHpAdjustedValue or 0)) ==
    (deputy.maxHp + (deputy.deputyMaxHpAdjustedValue or 0))
end

local function resolveChoice(room, player)
  if not player:isAlive() or not equalYinYang(player) then return end
  local choices = { "fengsui_heg__yuchen_draw" }
  if H.hasGeneral(player, true) then table.insert(choices, "fengsui_heg__yuchen_transform") end
  local choice = room:askToChoice(player, {
    choices = choices, skill_name = yuchen.name,
    prompt = "#fengsui_heg__yuchen-choice",
  })
  if choice == "fengsui_heg__yuchen_draw" then
    local n = math.max(0, player:getMaxCards() - player:getHandcardNum())
    if n > 0 then room:drawCards(player, n, yuchen.name) end
  else
    H.transformGeneral(room, player, false, false, 1, yuchen.name)
    if player:isAlive() and player:getMark("@!!companion") == 0 then
      H.addHegMark(player, "companion")
    end
  end
end

yuchen:addEffect("active", {
  anim_type = "support", prompt = "#fengsui_heg__yuchen-invoke",
  card_num = 0, target_num = 1,
  can_use = function(self, player)
    return player:hasShownSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      H.getGeneralsRevealedNum(player) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to, selected)
    return #selected == 0 and to ~= player and H.compareKingdomWith(to, player) and
      H.hasGeneral(player, true) and H.hasGeneral(to, true)
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    H.swapDeputy(room, player, target)
    resolveChoice(room, player)
    if target:isAlive() then resolveChoice(room, target) end
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__yuchen"] = "毓尘",
  [":fengsui_heg__yuchen"] = "出牌阶段限一次，你可以与一名其他同势力角色副将<a href='heg__yiwei'>易位</a>，易位前后控制此武将牌的角色中主副将阴阳鱼相等的角色依次（由你开始）选择一项：1.将手牌数摸至手牌上限；2.变更副将并获得一枚珠联璧合标记，然后移除此选项。",
  ["#fengsui_heg__yuchen-invoke"] = "毓尘：选择一名其他同势力角色，与其副将易位",
  ["#fengsui_heg__yuchen-choice"] = "毓尘：请选择一项",
  ["fengsui_heg__yuchen_draw"] = "将手牌数摸至手牌上限",
  ["fengsui_heg__yuchen_transform"] = "变更副将并获得珠联璧合标记",
}

return yuchen
