local s = fk.CreateSkill {name = "fengsui_heg__qingshi_jx"}
local RETURN_MARK = "fengsui_heg__qingshi_jx_return"

-- 选项2的牌并非都在使用结算后立刻进弃牌堆：延时锦囊（乐不思蜀、兵粮寸断、闪电）
-- 先置入目标判定区，要等判定或被拆时才进弃牌堆，挂在 UseCard 的退出时机上永远等不到。
-- 这里改成记录这些牌的id，等它们真的落进弃牌堆时再获得。
s:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local rec = player:getTableMark(RETURN_MARK)
    if #rec == 0 then return false end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(rec, info.cardId) then return true end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local rec = player:getTableMark(RETURN_MARK)
    local ids = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(rec, info.cardId) and room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    if #ids == 0 then return end
    room:setPlayerMark(player, RETURN_MARK, table.filter(rec, function(id)
      return not table.contains(ids, id)
    end))
    room:obtainCard(player, ids, true, fk.ReasonPrey, player, s.name)
  end,
})
-- 手牌与装备里至少有一张黑牌，否则问了「是否发动」也付不出代价。
local function hasBlackCard(player)
  for _, id in ipairs(player:getCardIds("he")) do
    local c = Fk:getCardById(id)
    if c and c.color == Card.Black then return true end
  end
  return false
end

s:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(s.name) and player:getMark(s.name .. "-round") == 0 and
      data.from ~= player and data.card.color == Card.Black and hasBlackCard(player)
  end,
  on_cost = function(self, event, _, player)
    local room = player.room
    -- 先问是否发动，再问弃哪张黑色牌；原来的弃牌框可取消，等于把两步压成一步。
    if not room:askToSkillInvoke(player, {
      skill_name = s.name,
      prompt = "#fengsui_heg__qingshi_jx-invoke",
    }) then return false end
    local cards = room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true,
      pattern = ".|.|black", skill_name = s.name, cancelable = true, skip = true,
      prompt = "#fengsui_heg__qingshi_jx-discard"})
    if #cards > 0 then event:setCostData(self, cards); return true end
  end,
  on_use = function(self, event, _, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), s.name, player, player)
    local choice = room:askToChoice(player, {choices = {"fengsui_heg__qingshi_jx_nullify", "fengsui_heg__qingshi_jx_obtain"},
      prompt = "#fengsui_heg__qingshi_jx-choice", skill_name = s.name})
    if choice == "fengsui_heg__qingshi_jx_nullify" then
      room:setPlayerMark(player, s.name .. "-round", 1)
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    else
      local rec = player:getTableMark(RETURN_MARK)
      local ids = Card:getIdList(data.card)
      if #ids == 0 then
        local id = data.card:getEffectiveId()
        if id and id > 0 then ids = { id } end
      end
      for _, id in ipairs(ids) do
        table.insertIfNeed(rec, id)
      end
      room:setPlayerMark(player, RETURN_MARK, rec)
    end
  end,
})
s:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return skill.name == s.name and from:getMark(s.name .. "-round") > 0
  end,
})
Fk:loadTranslationTable{
  ["fengsui_heg__qingshi_jx_nullify"] = "令此牌对你无效且本轮清饰失效",
  ["fengsui_heg__qingshi_jx_obtain"] = "此牌结算完毕后从弃牌堆获得之",
  ["#fengsui_heg__qingshi_jx-invoke"] = "清饰：你可以弃置一张黑色牌",
  ["#fengsui_heg__qingshi_jx-discard"] = "清饰：请弃置一张黑色牌",
  ["#fengsui_heg__qingshi_jx-choice"] = "清饰：请选择一项",
}
return s
