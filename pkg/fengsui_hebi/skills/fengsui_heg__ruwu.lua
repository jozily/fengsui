local H = require "packages.fengsui.hegemony_util"

local ruwu = fk.CreateSkill {
  name = "fengsui_heg__ruwu",
  tags = { Skill.Compulsory },
}
local resolvingMark = "fengsui_heg__ruwu_resolving"

local function ownedMarkCount(player)
  local total = 0
  for _, name in ipairs({ "yinyangfish", "vanguard", "companion", "wild",
      "fengsui_heg_ascend", "fengsui_heg__descend" }) do
    local key = (name == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend") or
      (name == "fengsui_heg__descend" and "@!!fengsui_heg__descend") or ("@!!" .. name)
    total = total + (tonumber(player:getMark(key)) or 0)
  end
  return total
end

local function resolve(player, target, markName)
  local room = player.room
  local amount = ownedMarkCount(player)
  room:drawCards(player, markName == "companion" and 2 or 1, ruwu.name)
  if player.dead or not target or H.compareKingdomWith(target, player) then return end
  local choices = { "fengsui_heg__ruwu_transform" }
  if #player:getCardIds("he") >= amount then
    table.insert(choices, 1, "fengsui_heg__ruwu_yinyang")
  end
  local choice = room:askToChoice(player, {
    choices = choices, skill_name = ruwu.name, prompt = "#fengsui_heg__ruwu-choice",
  })
  if choice == "fengsui_heg__ruwu_yinyang" then
    local cards = room:askToDiscard(player, {
      min_num = amount, max_num = amount, include_equip = true,
      skill_name = ruwu.name, prompt = "#fengsui_heg__ruwu-drop:::" .. amount,
      cancelable = false,
    })
    if #cards == amount and player:isAlive() then
      room:setPlayerMark(player, resolvingMark, 1)
      H.addHegMark(player, "yinyangfish")
      room:setPlayerMark(player, resolvingMark, 0)
    end
  elseif player:isAlive() then
    H.transformGeneral(room, player, false, false, 1, ruwu.name)
  end
end

ruwu:addEffect(H.HegMarkChanged, {
  global = true,
  anim_type = "drawcard",
  can_trigger = function(self, _, target, player, data)
    return target and target:isAlive() and player:isAlive() and player:hasSkill(ruwu.name) and player:getMark(resolvingMark) == 0 and data and
      data.markName and (data.action == "gain" or data.action == "use")
  end,
  on_use = function(self, _, target, player, data)
    resolve(player, target, data.markName)
  end,
})

return ruwu
