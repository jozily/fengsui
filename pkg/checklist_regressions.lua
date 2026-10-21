-- 清单中复杂分支的回归测试。通过眷故的 addTest 入口运行。
return function(suite)
  local function spec(name, timing)
    for _, effect in ipairs(Fk.skill_skels["fengsui_heg__" .. name].effect_spec_list) do
      if effect[1] == timing then return effect[3] end
    end
    error("Missing effect: " .. name)
  end
  local function actor(kingdom)
    return {
      id = 1, kingdom = kingdom or "wei", general = "caocao", deputyGeneral = "guojia", mark = {},
      getTableMark = function(self, key) return type(self.mark[key]) == "table" and self.mark[key] or {} end,
      getMark = function(self, key) return self.mark[key] or 0 end,
      hasSkill = function() return true end, hasShownSkill = function() return true end,
      isAlive = function(self) return not self.dead end,
      usedSkillTimes = function() return 0 end,
    }
  end
  local function skill(name) return {name = "fengsui_heg__" .. name} end
  suite:addTest(function()
    local callback = spec("jincai", fk.TargetSpecified)
    local owner, source = actor(), actor()
    local use = {setNullified = function(self) self.nullified = true end}
    local choices = {"fengsui_heg__jincai_hide", "fengsui_heg__jincai_main"}
    owner.room = {
      askToChoice = function() return table.remove(choices, 1) end,
      addTableMark = function() end,
    }
    source.room = owner.room
    source.hideGeneral = function(self, deputy) self.hidden = deputy and "d" or "m" end
    callback.on_use(skill("jincai"), nil, source, owner, {use = use})
    lu.assertEquals(source.hidden, "m")
    lu.assertNil(use.nullified)
    source.general = "anjiang"
    choices = {"fengsui_heg__jincai_hide"}
    callback.on_use(skill("jincai"), nil, source, owner, {use = use})
    lu.assertTrue(use.nullified)
    local obtained
    choices = {"fengsui_heg__jincai_obtain"}
    owner.room.obtainCard = function(_, player, card) obtained = {player, card} end
    local red = Fk:cloneCard("slash", Card.Heart)
    callback.on_use(skill("jincai"), nil, source, owner, {use = {}, card = red})
    lu.assertEquals(obtained, {owner, red})
  end)
  suite:addTest(function()
    local callback = spec("yisang", fk.PreCardUse)
    local current, other = actor(), actor()
    local room = {current = current, setPlayerMark = function(_, p, key, value) p.mark[key] = value end}
    current.room, other.room = room, room
    local first = {card = Fk:cloneCard("slash", Card.Heart)}
    callback.on_refresh(nil, nil, other, nil, first)
    lu.assertNil(first.extra_data.yisang_previous_color)
    local second = {card = Fk:cloneCard("duel", Card.Spade)}
    callback.on_refresh(nil, nil, current, nil, second)
    lu.assertEquals(second.extra_data.yisang_previous_color, Card.Red)
    lu.assertFalse(callback.can_refresh(nil, nil, current, nil, second))
    local response = {card = Fk:cloneCard("jink", Card.Heart)}
    spec("yisang", fk.CardResponding).on_refresh(nil, nil, other, nil, response)
    lu.assertEquals(response.extra_data.yisang_previous_color, Card.Black)
  end)
  suite:addTest(function()
    local owner, target = actor("wei"), actor("shu")
    local order = {}
    target.hideGeneral = function() table.insert(order, "hide") end
    target.drawCards = function(_, n) lu.assertEquals(n, 2); table.insert(order, "draw") end
    local room = {
      askToChoice = function(_, _, params) return params.choices[1] end,
      addTableMark = function() end,
      setPlayerMark = function(_, p, key, value) p.mark[key] = value end,
    }
    owner.room, target.room = room, room
    spec("chaohua", "active").on_use(skill("chaohua"), room, {from = owner, tos = {target}})
    lu.assertEquals(order, {"hide", "draw"})
    lu.assertEquals(owner.mark.fengsui_heg__chaohua_invalid_turn, nil)
    lu.assertEquals(owner:getMark("fengsui_heg__chaohua_invalid-turn"), 0)
  end)
  suite:addTest(function()
    local owner, victim = actor(), actor()
    owner.seat = 1
    victim.mark.fengsui_heg__jiaosu_target = 1
    victim.mark["@fengsui_heg__jiaosu_target"] = {"1"}
    local afterTurn, granted, reset
    local turn = {addExitFunc = function(_, fn) afterTurn = fn end}
    local room = {setPlayerMark = function(_, p, k, v) p.mark[k] = v end,
      logic = {getCurrentEvent = function() return {findParent = function() return turn end} end}}
    owner.room = room
    victim.reset = function() reset = true end
    victim.gainAnExtraPhase = function(_, phase, reason, delay)
      lu.assertEquals(phase, Player.Play); lu.assertFalse(delay); granted = true
    end
    spec("chuguang", fk.AfterDying).on_use(skill("chuguang"), nil, victim, owner)
    lu.assertTrue(reset)
    lu.assertNil(granted)
    lu.assertEquals(type(afterTurn), "function")
    afterTurn()
    lu.assertTrue(granted)
  end)
  suite:addTest(function()
    local owner, other = actor(), actor()
    local pile = {}
    owner.getPile = function() return pile end
    owner.room = {obtainCard = function(_, p, ids, visible, reason)
      lu.assertEquals(p, owner); lu.assertEquals(ids, pile); lu.assertTrue(visible); lu.assertEquals(reason, fk.ReasonPrey)
    end}
    local use = {tos = {owner, other}}
    local aim = {use = use, cancelTarget = function() error("Do not remove a target during its confirmation") end}
    local callback = spec("yinbing", fk.TargetConfirmed)
    callback.on_use(skill("yinbing"), nil, owner, owner, aim)
    lu.assertEquals(use.additionalEffectToPlayer[owner], 1)
    lu.assertNil(use.additionalEffectToPlayer[other])
    lu.assertNil(use.additionalEffect)
    pile = {1, 2}
    callback.on_use(skill("yinbing"), nil, owner, owner, aim)
    lu.assertEquals(use.nullifiedTargets, {owner})
    lu.assertEquals(#use.tos, 2)
  end)
  suite:addTest(function()
    local owner, receiver, source = actor(), actor(), actor()
    local given = Fk:getAllCardIds()[1]
    local card = Fk:getCardById(given)
    receiver.canPindian = function() return true end
    receiver.pindian = function()
      return {fromCard = Fk:cloneCard("slash", card.suit, 7), results = {
        [source] = {toCard = Fk:cloneCard("jink", card.suit, 7)},
      }}
    end
    local damage = {}
    owner.room = {showCards = function() end, moveCardTo = function() end,
      damage = function(_, data) table.insert(damage, {data.from, data.to}) end}
    local event = {getCostData = function() return {to = receiver, card = given} end}
    spec("shuge", fk.Damaged).on_use(skill("shuge"), event, owner, owner, {from = source})
    lu.assertEquals(#damage, 4)
    lu.assertEquals(damage, {{receiver, receiver}, {receiver, source}, {source, receiver}, {source, source}})
  end)
  suite:addTest(function()
    local owner, target = actor(), actor()
    local calls = {}
    owner.gainAnExtraTurn = function(_, delay) lu.assertTrue(delay); table.insert(calls, "turn") end
    local invoke = false
    local room = {
      useVirtualCard = function() table.insert(calls, "known_both"); return {} end,
      askToSkillInvoke = function() return invoke end,
      askToChoice = function() return "anshi_extra_turn" end,
      handleAddLoseSkills = function(_, _, name) lu.assertEquals(name, "-fengsui_heg__anshi"); table.insert(calls, "lose") end,
    }
    local callback = spec("anshi", "active")
    callback.on_use(skill("anshi"), room, {from = owner, tos = {target}})
    lu.assertEquals(calls, {"known_both"})
    calls, invoke = {}, true
    callback.on_use(skill("anshi"), room, {from = owner, tos = {target}})
    lu.assertEquals(calls, {"known_both", "turn", "lose"})
  end)
  suite:addTest(function()
    local owner, target = actor(), actor()
    local callback = spec("qujian", fk.Damaged)
    local card = Fk:cloneCard("thunder__slash")
    card.skillName = "fengsui_heg__qujian"
    lu.assertTrue(callback.can_trigger(nil, nil, target, owner, {from = owner, card = card}))
    lu.assertFalse(callback.can_trigger(nil, nil, target, owner, {from = target, card = card}))
    local chained
    target.setChainState = function(_, value) chained = value end
    callback.on_use(nil, nil, target)
    lu.assertTrue(chained)
  end)
  suite:addTest(function()
    local owner, recipient = actor(), actor()
    owner.general, owner.deputyGeneral = "fengsui_heg__douwudoumiao", "guojia"
    local hidden
    owner.hideGeneral = function(_, deputy) hidden = deputy end
    local callback = spec("youhuan", fk.DamageInflicted)
    local data = {from = owner, damage = 1, changeDamage = function(self, n) self.damage = self.damage + n end}
    lu.assertTrue(callback.can_trigger(skill("youhuan"), nil, recipient, owner, data))
    lu.assertTrue(callback.on_use(skill("youhuan"), nil, recipient, owner, data))
    lu.assertEquals(data.damage, 0)
    lu.assertFalse(hidden)
  end)
  suite:addTest(function()
    local owner = actor()
    local lost = 0
    owner.room = {alive_players = {}, loseHp = function(_, p, n)
      lu.assertEquals(p, owner); lost = lost + n
    end}
    local callback = spec("chongjing", fk.AfterCardsMove)
    local data = {{from = owner, moveReason = fk.ReasonRecast, moveInfo = {{cardId = 1}}}}
    lu.assertTrue(callback.can_trigger(skill("chongjing"), nil, nil, owner, data))
    callback.on_use(skill("chongjing"), nil, nil, owner, data)
    lu.assertEquals(lost, 1)
    data[1].from = actor()
    lu.assertFalse(callback.can_trigger(skill("chongjing"), nil, nil, owner, data))
  end)
  suite:addTest(function()
    local callback = spec("qiju", "targetmod")
    local owner, unknown = actor(), actor("unknown")
    owner.general, owner.deputyGeneral = "fengsui_heg__zhugelian", "anjiang"
    unknown.deputyGeneral = "anjiang"
    owner.mark["fengsui_heg__qiju_used"] = 1
    unknown.kingdom = "unknown"
    owner.room = {alive_players = {owner, unknown}}
    local slash = {name = "slash", trueName = "slash"}
    lu.assertTrue(callback.mod_target_filter({}, owner, unknown, {}, slash))
    lu.assertTrue(callback.bypass_times({}, owner, nil, nil, slash, unknown))
    lu.assertTrue(callback.bypass_distances({}, owner, nil, slash, unknown))
  end)
  suite:addTest(function()
    local callback = spec("shenyu", fk.TurnEnd)
    local owner, target = actor(), actor()
    target.hp = 3
    target.getHandcardNum = function() return target.hand end
    target.mark["fengsui_heg__shenyu-discard"] = 3
    target.hand = 3
    local skill = {name = "fengsui_heg__shenyu"}
    lu.assertFalse(callback.can_trigger(skill, nil, target, owner, {}))
    target.hand = 2
    lu.assertTrue(callback.can_trigger(skill, nil, target, owner, {}))
  end)
  suite:addTest(function()
    local siji_events = Fk.skill_skels["fengsui_heg__siji"].effect_spec_list
    local found_turn_end = false
    for _, effect in ipairs(siji_events) do
      if effect[1] == fk.TurnEnd then found_turn_end = true end
    end
    lu.assertTrue(found_turn_end)
  end)
  suite:addTest(function()
    local callback = spec("siji", fk.Damaged)
    local owner, target = actor(), actor()
    local choices = {"fengsui_heg__siji_up", "fengsui_heg__siji_down"}
    local draws, discards, marks = 0, 0, {}
    owner.isNude = function() return false end
    target.getMaxCards = function() return 4 end
    local room = {current = target,
      askToChoice = function() return table.remove(choices, 1) end,
      drawCards = function(_, p, n) draws = draws + n end,
      askToDiscard = function() discards = discards + 1 end,
      addPlayerMark = function(_, p, key, n) marks[key] = n end,
      setPlayerMark = function() end,
      broadcastProperty = function() end,
    }
    owner.room = room
    callback.on_use(skill("siji"), nil, nil, owner, {})
    callback.on_use(skill("siji"), nil, nil, owner, {})
    lu.assertEquals(draws, 1)
    lu.assertEquals(discards, 1)
    lu.assertEquals(marks[MarkEnum.AddMaxCardsInTurn], 1)
    lu.assertEquals(marks[MarkEnum.MinusMaxCardsInTurn], 1)
  end)
  suite:addTest(function()
    local round_effect
    for _, effect in ipairs(Fk.skill_skels["fengsui_heg__tishi"].effect_spec_list) do
      if effect[1] == fk.RoundStart then round_effect = effect[3] end
    end
    lu.assertNotNil(round_effect)
    local owner, unrelated = actor(), actor()
    owner.room = {players = {owner, unrelated}}
    unrelated.hasSkill = function() return false end
    owner.room.setPlayerMark = function(_, p, key, value)
      p.mark[key] = value
    end
    local skill = {name = "fengsui_heg__tishi"}
    lu.assertTrue(round_effect.can_refresh(skill, nil, unrelated, owner, {}))
    lu.assertFalse(round_effect.can_refresh(skill, nil, unrelated, unrelated, {}))
    round_effect.on_refresh(skill, nil, unrelated, owner, {})
    lu.assertEquals(owner:getMark("fengsui_heg__tishi-1-round"), 0)
    lu.assertEquals(unrelated:getMark("fengsui_heg__tishi-1-round"), 0)
  end)
  suite:addTest(function()
    lu.assertEquals(Fk:translate("$fengsui_heg__jianhe1"), "此剑光芒艳发，非凡物也，当以华阴赤土拭之。")
    lu.assertEquals(Fk:translate("$fengsui_heg__jianhe2"), "斗牛间常有紫气，其兆如何，还请阁下解之。")
    lu.assertEquals(Fk:translate("$fengsui_heg__cangjuan1"), "赤心如丹，思虑王室之险。")
    lu.assertEquals(Fk:translate("$fengsui_heg__cangjuan2"), "气节如玉，心忧国家之难。")
  end)
  suite:addTest(function()
    lu.assertEquals(Fk:translate("fengsui_heg__yandu_type_1"), "基本牌")
    lu.assertEquals(Fk:translate("fengsui_heg__yandu_type_2"), "锦囊牌")
    lu.assertEquals(Fk:translate("fengsui_heg__yandu_type_3"), "装备牌")
    lu.assertNotEquals(Fk:translate("fengsui_heg__yandu_type_1"), "锦囊牌")
  end)
  suite:addTest(function()
    local name = "fengsui_toaru__heg__duxin"
    lu.assertEquals(Fk:translate(":" .. name),
      "当你明置或暗置武将牌时，你可以视为使用一张不可响应的【知己知彼】并摸一张牌。")
    local owner, other = actor(), actor()
    local used, drawn = 0, 0
    local room = {players = {owner, other}, alive_players = {owner, other}}
    owner.room = room
    owner.canUseTo = function(_, card, target) return card.name == "known_both" and target == other end
    owner.drawCards = function(_, n, reason)
      lu.assertEquals(reason, name); drawn = drawn + n
    end
    room.askToSkillInvoke = function() return true end
    room.askToUseVirtualCard = function(_, who, params)
      lu.assertEquals(who, owner)
      lu.assertEquals(params.name, "known_both")
      lu.assertTrue(params.skip)
      lu.assertFalse(params.cancelable)
      return {from = owner, tos = {other}, card = Fk:cloneCard("known_both")}
    end
    room.useCard = function(_, use)
      lu.assertEquals(use.disresponsiveList, room.players)
      used = used + 1
    end
    local seen = {}
    for _, effect in ipairs(Fk.skill_skels[name].effect_spec_list) do
      local timing, callback = effect[1], effect[3]
      if timing == fk.GeneralRevealed or timing == fk.GeneralHidden then
        lu.assertNotNil(callback.can_trigger(nil, nil, owner, owner, {}))
        lu.assertFalse(callback.can_trigger(nil, nil, other, owner, {}))
        lu.assertTrue(callback.on_cost(nil, nil, owner, owner, {}))
        callback.on_use(nil, nil, owner, owner, {})
        seen[timing] = true
      end
    end
    lu.assertTrue(seen[fk.GeneralRevealed])
    lu.assertTrue(seen[fk.GeneralHidden])
    lu.assertEquals(used, 2)
    lu.assertEquals(drawn, 2)
  end)
  suite:addTest(function()
    lu.assertNil(Fk.generals.fengsui_heg__caoshi)
    lu.assertEquals(Fk:translate("fengsui_heg__caocen"), "曹涔")
    lu.assertEquals(Fk.generals.fengsui_heg__zuosizuofen.maxHp, 3)
    lu.assertEquals(Fk.generals.fengsui_heg__douwudoumiao.maxHp, 4)
    lu.assertEquals(Fk.generals.fengsui_heg__zuosizuofen.gender, General.Bigender)
    lu.assertTrue(Fk.skills.fengsui_heg__jianhe:hasTag(Skill.MainPlace))
    lu.assertTrue(Fk.skills.fengsui_heg__yinbing:hasTag(Skill.DeputyPlace))
    lu.assertFalse(Fk.skills.fengsui_heg__ruwu:hasTag(Skill.DeputyPlace))
    lu.assertStrContains(Fk:translate(":fengsui_heg__ranlv"), "href='heg__hebi'")
    lu.assertStrContains(Fk:translate("heg__hebi"), "如果没有与之配对的珠联璧合对象则自动变更副将")
    lu.assertNotStrContains(Fk:translate(":fengsui_heg__chenji"), "死亡")
    lu.assertNotStrContains(Fk:translate(":fengsui_heg__yinyu"), "徐庶")
    lu.assertStrContains(Fk:translate(":fengsui_heg__baoguo"), "若你为小势力角色")
  end)
  suite:addTest(function()
    local owner, source, target = actor(), actor(), actor()
    source.general, target.general = "fengsui_heg__xuncan", "fengsui_heg__caocen"
    source.id = 2
    local first, current = {id = 1}, {id = 2}
    source.room = {current = source, logic = {
      getCurrentEvent = function() return {findParent = function() return current end} end,
      getEventsOfScope = function() return {first} end,
    }}
    local callback = spec("juangu", fk.TargetSpecified)
    local data = {to = target, card = Fk:cloneCard("slash")}
    lu.assertFalse(callback.can_trigger(nil, nil, source, owner, data))
    current = first
    lu.assertTrue(callback.can_trigger(nil, nil, source, owner, data))
    owner.mark["fengsui_heg__juangu_used-turn"] = {source.id}
    lu.assertFalse(callback.can_trigger(nil, nil, source, owner, data))
  end)
  suite:addTest(function()
    local owner, source = actor(), actor()
    source.phase = Player.Finish
    local damages = {}
    owner.room = {logic = {getEventsOfScope = function(_, event)
      if event == GameEvent.Damage then return damages end
      return {{data = {{to = owner, toArea = Card.PlayerHand, moveInfo = {{}, {}}}}}}
    end}}
    local callback = spec("choutao", fk.EventPhaseStart)
    lu.assertFalse(callback.can_trigger(nil, nil, source, owner))
    damages = {{exec_ret = true, data = {to = owner, damage = 1}}}
    lu.assertTrue(callback.can_trigger(nil, nil, source, owner))
    damages[1].exec_ret = false
    lu.assertFalse(callback.can_trigger(nil, nil, source, owner))
    damages[1].exec_ret, damages[1].data.damage = true, 2
    lu.assertFalse(callback.can_trigger(nil, nil, source, owner))
  end)
  suite:addTest(function()
    local owner = actor()
    local ids = table.slice(Fk:getAllCardIds(), 1, 3)
    local failed, obtained = 0, {}
    local room = {draw_pile = ids, discard_pile = {},
      getNCards = function(_, n, pos) lu.assertEquals(n, 2); lu.assertEquals(pos, "bottom"); return ids end,
      moveCards = function() end, showCards = function() end,
      getCardArea = function() return Card.Processing end,
      askToUseRealCard = function(_, _, params) lu.assertFalse(params.cancelable); return nil end,
      obtainCard = function(_, _, id) table.insert(obtained, id) end,
      loseHp = function(_, _, n) failed = failed + n end,
      logic = {getEventsOfScope = function()
        return {{data = {card = Fk:cloneCard("slash")}}, {data = {card = Fk:cloneCard("duel")}}}
      end},
    }
    owner.room = room
    spec("fuyin", fk.TurnEnd).on_use(skill("fuyin"), nil, nil, owner)
    lu.assertEquals(obtained, ids)
    lu.assertEquals(failed, 1)
  end)
  suite:addTest(function()
    local owner = actor()
    local id = Fk:getAllCardIds()[1]
    local callback = spec("jianhe", "viewas")
    local card = callback.view_as(nil, owner, {id})
    lu.assertEquals(card.suit, Fk:getCardById(id).suit)
    lu.assertEquals(card.number, Fk:getCardById(id).number)
    lu.assertEquals(Card:getIdList(card), {id})
    lu.assertFalse(callback.enabled_at_response(nil, owner, true))
  end)

end
