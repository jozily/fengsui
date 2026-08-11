local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local qiangong = fk.CreateSkill{
  name = "fengsui_heg__qiangong",
}

local function emptiedAreaCount(move)
  if not move.from then return 0 end
  local counts = {h = 0, e = 0, j = 0}
  for _, info in ipairs(move.moveInfo) do
    if info.fromArea == Card.PlayerHand then counts.h = counts.h + 1 end
    if info.fromArea == Card.PlayerEquip then counts.e = counts.e + 1 end
    if info.fromArea == Card.PlayerJudge then counts.j = counts.j + 1 end
  end
  local n = 0
  if counts.h > 0 and move.from:isKongcheng() then n = n + counts.h end
  if counts.e > 0 and #move.from:getCardIds("e") == 0 then n = n + counts.e end
  if counts.j > 0 and #move.from:getCardIds("j") == 0 then n = n + counts.j end
  return n
end

qiangong:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(qiangong.name) or not H.allGeneralsRevealed(player) then return false end
    return table.find(data, function(move)
      return move.from and move.from:isAlive() and H.compareKingdomWith(move.from, player) and
        emptiedAreaCount(move) > 0
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local entries = {}
    for _, move in ipairs(data) do
      local n = emptiedAreaCount(move)
      if n > 0 and move.from:isAlive() and H.compareKingdomWith(move.from, player) then
        entries[move.from.id] = (entries[move.from.id] or 0) + n
      end
    end
    local targets = {}
    for id, _ in pairs(entries) do
      local p = player.room:getPlayerById(id)
      if p then table.insert(targets, p) end
    end
    local chosen = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = qiangong.name,
      prompt = "#fengsui_heg__qiangong-invoke",
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1], n = entries[chosen[1].id]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    U.hideSkillGeneral(player, qiangong.name)
    if cost.to:isAlive() then cost.to:drawCards(cost.n, qiangong.name) end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__qiangong-invoke"] = "避尊：暗置此武将牌，令一名失去区域内所有牌的同势力角色摸等量张牌",
}

return qiangong
