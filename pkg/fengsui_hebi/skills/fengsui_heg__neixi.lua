local H = require "packages.fengsui.hegemony_util"

local neixi = fk.CreateSkill{
  name = "fengsui_heg__neixi",
}
neixi:addEffect("active", {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#fengsui_heg__neixi-active",
  can_use = function(self, player)
    return player:usedSkillTimes(neixi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from

    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng() and H.compareKingdomWith(p, player)
    end)
    if #targets == 0 then return end

    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#fengsui_heg__neixi-targets",
      skill_name = neixi.name,
      cancelable = true,
    })

    if #tos == 0 then return end
    room:sortByAction(tos)

    -- 依次展示手牌
    local cards_info = {}
    local valid_tos = {}
    for _, p in ipairs(tos) do
      if not p.dead and not p:isKongcheng() then
        local cid = room:askToChooseCard(p, {
          target = p,
          flag = "h",
          skill_name = neixi.name,
          prompt = "#fengsui_heg__neixi-show",
        })
        room:showCards({cid}, p)
        table.insert(cards_info, Fk:getCardById(cid))
        table.insert(valid_tos, {player = p, card_id = cid})
      end
    end

    if #cards_info > 0 then
      local same_color, same_type = true, true
      local base_color = cards_info[1].color
      local base_type = cards_info[1].type
      for i = 2, #cards_info do
        if cards_info[i].color ~= base_color then same_color = false end
        if cards_info[i].type ~= base_type then same_type = false end
      end

      -- 判断条件：如果所有展出牌颜色均等或类别均等
      if same_color or same_type then
        for _, info in ipairs(valid_tos) do
          local p = info.player
          local cid = info.card_id
          if p.dead then goto continue end

          local x = H.getGeneralsRevealedNum(p)
          if x > 0 then p:drawCards(x, neixi.name) end

          if p.dead or not table.contains(p:getCardIds("h"), cid) then goto continue end
          room:askToUseRealCard(p, {
             pattern = {cid},
             skill_name = neixi.name,
             prompt = "#fengsui_heg__neixi-use",
          })

          ::continue::
        end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__neixi"] = "内嬉",
  [":fengsui_heg__neixi"] = "出牌阶段限一次，你可以令任意名同势力角色依次展示一张手牌，若颜色或类别均相等，其可摸X张牌并使用此牌（X为其明置武将牌数）。",
  ["#fengsui_heg__neixi-active"] = "内嬉：选择任意名同势力角色",
  ["#fengsui_heg__neixi-targets"] = "内嬉：令他们各展示一张牌，若类别/颜色一致则可发牌并用牌",
  ["#fengsui_heg__neixi-show"] = "内嬉：请展示一张手牌",
  ["#fengsui_heg__neixi-use"] = "内嬉：由于满足一致条件，你可以使用你展示的牌",
}

return neixi
