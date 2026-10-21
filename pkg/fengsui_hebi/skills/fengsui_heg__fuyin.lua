local fuyin = fk.CreateSkill{
  name = "fengsui_heg__fuyin",
  tags = { Skill.Compulsory },
}

local function usedTypes(player)
  local types = {}
  for _, event in ipairs(player.room.logic:getEventsOfScope(GameEvent.UseCard, 9999,
      function(e) return e.data and e.data.from == player end, Player.HistoryTurn)) do
    local card = event.data.card
    if card then types[card.type] = true end
  end
  local n = 0
  for _ in pairs(types) do n = n + 1 end
  return math.max(1, n)
end

fuyin:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(fuyin.name) and
      #player.room.draw_pile + #player.room.discard_pile > 0
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local n = usedTypes(player)
    if n <= 0 then return end
    local ids = room:getNCards(n, "bottom")
    room:moveCards {
      ids = ids, toArea = Card.Processing, moveReason = fk.ReasonJustMove,
      skillName = fuyin.name, moveVisible = true,
    }
    room:showCards(ids, player)
    local failed = false
    for _, id in ipairs(ids) do
      if player.dead then break end
      local card = Fk:getCardById(id)
      if not card or room:getCardArea(id) ~= Card.Processing then
        failed = true
      else
        local use = room:askToUseRealCard(player, {
          pattern = tostring(Exppattern{ id = { id } }),
          skill_name = fuyin.name,
          prompt = ":fengsui_heg__fuyin",
          cancelable = false,
          skip = true,
          expand_pile = { id },
          extra_data = { bypass_times = true },
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        else
          failed = true
          room:obtainCard(player, id, true, fk.ReasonPrey, player, fuyin.name)
        end
      end
    end
    if failed and player:isAlive() then room:loseHp(player, 1, fuyin.name) end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__fuyin"] = "负胤",
  [":fengsui_heg__fuyin"] = "锁定技，回合结束时，你亮出牌堆底的X张牌并依次使用其中的牌，若其中有无法被使用的牌，你获得之并失去一点体力（X为你本回合使用过牌的类别数且至少为1）。",
}

return fuyin
