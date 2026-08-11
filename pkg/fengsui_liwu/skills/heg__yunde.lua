local heg__yunde = fk.CreateSkill {
    name = "heg__yunde",
}

Fk:loadTranslationTable {
    ["heg__yunde"] = "匀德",
    [":heg__yunde"] = "出牌阶段开始时，你可以视为对一名其他角色使用一张【知己知彼】，此牌结算完成后，" ..
    "其可以明置一张武将牌并令你跳过弃牌阶段；" ..
    "若其与你势力相同，你与其各摸一张牌，否则你令其本回合内不可使用或打出<font color='red'>♥</font>牌。",

    ["#heg__yunde"] = "匀德：选择一名其他角色，视为对其使用【知己知彼】",
    ["#heg__yunde-ask"] = "匀德：选择是否明置一张武将牌，令 %src 跳过弃牌阶段",
    ["@@heg__yunde-turn"] = "匀德 禁牌",
}

local H = require "packages.fengsui.hegemony_util"

heg__yunde:addEffect(fk.EventPhaseChanging, {
    anim_type = "control",
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(heg__yunde.name) and
            data.phase == Player.Play and not data.skipped
            and not player:prohibitUse(Fk:cloneCard("known_both"))
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        local targets = room:getOtherPlayers(player)
        if #targets > 0 then
            local tos = room:askToChoosePlayers(player, {
                targets = targets,
                min_num = 1,
                max_num = 1,
                prompt = "#heg__yunde",
                skill_name = heg__yunde.name,
                cancelable = true,
            })
            if #tos > 0 then
                event:setCostData(self, { tos = tos })
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = event:getCostData(self).tos[1]
        if to.dead or player.dead then return end
        room:useVirtualCard("known_both", nil, player, to, heg__yunde.name, true)
        if not H.allGeneralsRevealed(to) then
            if H.askToRevealGenerals(to, {
                    skill_name = heg__yunde.name,
                    prompt = "#heg__yunde-ask:" .. player.id,
                    revealAll = false, }) ~= "Cancel" then
                player:skip(Player.Discard)
            end
        end
    end,
})

heg__yunde:addEffect(fk.CardUseFinished, {
    is_delay_effect = true,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(heg__yunde.name) and data.card.name == "known_both"
            and table.contains(data.card.skillNames, heg__yunde.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = data.tos[1]
        if H.compareKingdomWith(to, player) then
            if player.dead or to.dead then return end
            player:drawCards(1, heg__yunde.name)
            to:drawCards(1, heg__yunde.name)
        else
            room:setPlayerMark(to, "@@heg__yunde-turn", 1)
        end
    end,
})

heg__yunde:addEffect("prohibit", {
    prohibit_use = function(self, player, card)
        if player:getMark("@@heg__yunde-turn") > 0 then
            return card and card:getSuitString(false) == "heart"
        end
    end,
    prohibit_response = function(self, player, card)
        if player:getMark("@@heg__yunde-turn") > 0 then
            return card and card:getSuitString(false) == "heart"
        end
    end,
})

return heg__yunde
