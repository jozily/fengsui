local H = require "packages.fengsui.hegemony_util"
local lianxi = fk.CreateSkill { name = "fengsui_heg__lianxi", tags = { Skill.Compulsory } }

local function resolve(self, _, target, player)
  local room = player.room
  local choice = room:askToChoice(target, {
    choices = { "fengsui_heg__lianxi_discard", "fengsui_heg__lianxi_swap" },
    skill_name = self.name,
    prompt = "#fengsui_heg__lianxi-choice",
  })
  if choice == "fengsui_heg__lianxi_discard" then
    local areas = {}
    if not target:isKongcheng() then table.insert(areas, "fengsui_heg__lianxi_hand") end
    if #target:getCardIds("e") > 0 then table.insert(areas, "fengsui_heg__lianxi_equip") end
    if #target:getCardIds("j") > 0 then table.insert(areas, "fengsui_heg__lianxi_judge") end
    if #areas == 0 then return end
    local area = room:askToChoice(target, { choices = areas, skill_name = self.name })
    local cards = area == "fengsui_heg__lianxi_hand" and target:getCardIds("h") or
      area == "fengsui_heg__lianxi_equip" and target:getCardIds("e") or target:getCardIds("j")
    room:throwCard(cards, self.name, target, player)
    local current = room.current
    if current and current:isAlive() then
      room:damage { from = target, to = current, damage = 1, skillName = self.name }
    end
  else
    local tos = table.filter(room.alive_players, function(p)
      return p ~= player and p ~= target and H.compareKingdomWith(p, player)
    end)
    if #tos > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = tos, min_num = 1, max_num = 1, skill_name = self.name,
        prompt = "#fengsui_heg__lianxi-swap",
      })[1]
      if to then H.swapDeputy(room, player, to) end
    end
  end
end

for _, event in ipairs({ fk.GeneralRevealed, fk.GeneralHidden }) do
  lianxi:addEffect(event, {
    global = true,
    can_trigger = function(self, _, target, player)
      return target and target ~= player and target:isAlive() and player:hasSkill(self.name) and
        H.compareKingdomWith(target, player)
    end,
    on_use = resolve,
  })
end

Fk:loadTranslationTable {
  ["#fengsui_heg__lianxi-choice"] = "连徙：请选择一项",
  ["#fengsui_heg__lianxi-swap"] = "连徙：请选择一名同势力角色进行副将易位",
  ["fengsui_heg__lianxi_discard"] = "弃置一个区域所有牌并对当前回合角色造成1点伤害",
  ["fengsui_heg__lianxi_swap"] = "与一名同势力角色副将易位",
  ["fengsui_heg__lianxi_hand"] = "手牌区",
  ["fengsui_heg__lianxi_equip"] = "装备区",
  ["fengsui_heg__lianxi_judge"] = "判定区",
}

return lianxi
