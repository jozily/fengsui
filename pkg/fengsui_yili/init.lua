local extension = Package:new("fengsui_yili")
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode" }

Fk:appendKingdomMap("fengsui_neutral", { "wei", "shu", "wu", "qun", "jin" })
require("packages.fengsui.pkg.fengsui_yili.neutral_compat").install()

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_yili/skills")

local jiaxu = General:new(extension, "fengsui_heg__jiaxu", "fengsui_neutral", 3)
jiaxu:addCompanions("hs__jiaxu")
jiaxu:addSkill("fengsui_heg__qingshi_jx")
jiaxu:addSkill("fengsui_heg__anshi")
jiaxu:addSkill("fengsui_heg__shuge")
jiaxu:addSkill("fengsui_heg__suoli")

local lusu = General:new(extension, "fengsui_heg__lusu", "fengsui_neutral", 3)
lusu:addCompanions("hs__lusu")
lusu:addSkill("fengsui_heg__xiangkui")
lusu:addSkill("fengsui_heg__yangming")
lusu:addSkill("fengsui_heg__suoli")

local xushu = General:new(extension, "fengsui_heg__xushu", "fengsui_neutral", 4)
xushu.mainMaxHpAdjustedValue = -1
xushu:addCompanions("ld__xushu")
xushu:addSkill("fengsui_heg__jiange")
xushu:addSkill("fengsui_heg__xiawang")
xushu:addSkill("fengsui_heg__yinyu")
xushu:addSkill("fengsui_heg__suoli")

local zhaoe = General:new(extension, "fengsui_heg__zhaoe", "fengsui_neutral", 3)
zhaoe.gender = General.Female
zhaoe:addSkill("fengsui_heg__yanshi")
zhaoe:addSkill("fengsui_heg__xinren")
zhaoe:addSkill("fengsui_heg__suoli")

local xushao = General:new(extension, "fengsui_heg__xushao", "fengsui_neutral", 3)
xushao:addCompanions("fengsui_heg__xujing")
xushao:addSkill("fengsui_heg__yingmen")
xushao:addSkill("fengsui_heg__pingjian")
xushao:addSkill("fengsui_heg__suoli")

assert(#extension.generals == 5, "fengsui_yili must load exactly 5 generals")
assert(#extension.skill_skels == 16, "fengsui_yili must load exactly 16 skill skeletons")

Fk:loadTranslationTable{
  ["fengsui_yili"] = "烽燧燎原-屹砺",
  ["fengsui_neutral"] = "中立",
  ["heg__zhongliji"] = "中立技：确定势力后失去的技能。<br>中立者：单独亮明中立者时按单独势力计算，但属于未确定势力角色，可搭配任意势力武将牌。最终势力和获胜条件随有势力的武将牌一方；若一方为双势力角色则亮明该武将牌时需声明所属势力；中立者无法与野心家或另一中立者组合。中立者若阵亡时仍未确定势力，则按照单独势力处理奖惩。需先亮明中立者武将牌一轮后或受到伤害后才可亮明另一张武将牌（部分技能可无视该条件）。中立者明置后获得【索立】。<br>",

  ["fengsui_heg__jiaxu"] = "贾诩",
  ["#fengsui_heg__jiaxu"] = "踱步逆世",
  ["~fengsui_heg__jiaxu"] = "乱世谋身，终难独善……",
  ["designer:fengsui_heg__jiaxu"] = "公冶天纵",
  ["illustrator:fengsui_heg__jiaxu"] = "佚名",
  ["cv:fengsui_heg__jiaxu"] = "暂无",
  ["fengsui_heg__qingshi_jx"] = "清饰",
  [":fengsui_heg__qingshi_jx"] = "每轮限一次，当你成为其他角色黑色锦囊牌或【杀】的目标后，你可弃置一张手牌令此牌对你无效。若你弃置的为黑色牌，你摸一张牌。",
  ["fengsui_heg__anshi"] = "谙世",
  [":fengsui_heg__anshi"] = "出牌阶段限一次，你可以视为使用一张【知己知彼】，若你选择观看其武将牌后，其势力与你一致且你未确定势力，其可选择明置之，然后你明置另一张武将牌并令其于本回合结束后获得一个额外的回合。若你已确定势力，你令目标将手牌调整至手牌上限。",
  ["fengsui_heg__shuge"] = "束阁",
  [":fengsui_heg__shuge"] = "<a href='heg__zhongliji'>中立技</a>，当你受到伤害后，你可以将一张伤害牌正面朝上交给一名伤害来源外的角色并令其与伤害来源拼点，赢者对败者使用此牌。若拼点中有角色使用你展示的牌拼点，则其受到1点无来源的雷电伤害。",
  ["$fengsui_heg__qingshi_jx1"] = "清者自清，何须辩白。",
  ["$fengsui_heg__qingshi_jx2"] = "饰以虚名，不如藏拙。",
  ["$fengsui_heg__anshi1"] = "世事洞明皆学问，人情练达即文章。",
  ["$fengsui_heg__anshi2"] = "谙尽世情，方知进退。",
  ["$fengsui_heg__shuge1"] = "东阁之中，自有乾坤。",
  ["$fengsui_heg__shuge2"] = "借刀杀人，何须亲为。",

  ["fengsui_heg__lusu"] = "鲁肃",
  ["#fengsui_heg__lusu"] = "善施者",
  ["~fengsui_heg__lusu"] = "天下大势，非一人可定……",
  ["designer:fengsui_heg__lusu"] = "公冶天纵",
  ["illustrator:fengsui_heg__lusu"] = "佚名",
  ["cv:fengsui_heg__lusu"] = "暂无",
  ["fengsui_heg__xiangkui"] = "飨馈",
  [":fengsui_heg__xiangkui"] = "其他角色的出牌阶段限一次，其可指定一种类型，然后你可正面朝上交给其任意张手牌并摸交出类别张牌。若以此法交给其的牌中包含其指定的类型，你摸两张牌。",
  ["fengsui_heg__yangming"] = "扬名",
  [":fengsui_heg__yangming"] = "<a href='heg__zhongliji'>中立技</a>，每个回合结束时，你可以摸X张牌，若X不小于场上势力数，你需展示所有手牌并依次选择X张牌和X名势力不同的其他角色，这些角色依次获得一张你选择的牌。（X为你本回合使用的牌的类别数）",
  ["$fengsui_heg__xiangkui1"] = "飨以美食，馈以诚心。",
  ["$fengsui_heg__xiangkui2"] = "有朋远来，不亦乐乎。",
  ["$fengsui_heg__yangming1"] = "名扬四海，德被苍生。",
  ["$fengsui_heg__yangming2"] = "善施者，天下归心。",

  ["fengsui_heg__xushu"] = "徐庶",
  ["#fengsui_heg__xushu"] = "奇侠",
  ["~fengsui_heg__xushu"] = "此志未竟，恨难瞑目……",
  ["designer:fengsui_heg__xushu"] = "公冶天纵",
  ["illustrator:fengsui_heg__xushu"] = "佚名",
  ["cv:fengsui_heg__xushu"] = "暂无",
  ["fengsui_heg__jiange"] = "剑歌",
  [":fengsui_heg__jiange"] = "每回合限一次，你可以将一张锦囊牌或装备牌当作【杀】或【决斗】使用或打出，然后你摸一张牌。",
  ["fengsui_heg__xiawang"] = "侠望",
  [":fengsui_heg__xiawang"] = "<a href='heg__zhongliji'>中立技</a>，当与你距离不大于1的角色受到伤害后，若伤害来源不为你，你可对伤害来源使用一张可用的伤害牌（无距离限制）。",
  ["fengsui_heg__yinyu"] = "隐誉",
  [":fengsui_heg__yinyu"] = "主将技，锁定技，你计算体力上限时减少1个单独的阴阳鱼。当你确定势力后，若你为群或蜀势力，你获得“诛恶”或“辅主”；若你的副将为徐庶（蜀），你移除此武将牌，并令另一张武将牌变为主将，其获得该武将牌上的技能并将“荐才”变为主将技。",
  ["fengsui_heg__zhue"] = "诛恶",
  [":fengsui_heg__zhue"] = "群势力技，每轮限一次，当一名同势力角色使用非装备牌时，你可令其摸一张牌且此牌不能被响应。",
  ["fengsui_heg__fuzhu_xs"] = "辅主",
  [":fengsui_heg__fuzhu_xs"] = "蜀势力技，每轮各限一次，当一名同势力角色使用非转化牌或转化牌结算结束后，你可以将一张牌置于牌堆顶或底，然后展示牌堆底或顶的三张牌并获得其中一种类别的牌，并将其余的牌以任意顺序置于原位。",
  ["$fengsui_heg__jiange1"] = "剑鸣风起，歌啸长空。",
  ["$fengsui_heg__jiange2"] = "一剑一歌，快意恩仇。",
  ["$fengsui_heg__xiawang1"] = "侠之大者，为国为民。",
  ["$fengsui_heg__xiawang2"] = "路见不平，拔剑相助。",
  ["$fengsui_heg__yinyu1"] = "隐于市井，誉满天下。",
  ["$fengsui_heg__yinyu2"] = "功成不居，名隐于世。",

  ["fengsui_heg__zhaoe"] = "赵娥",
  ["#fengsui_heg__zhaoe"] = "覆水之仇",
  ["~fengsui_heg__zhaoe"] = "血仇已报，此生无憾……",
  ["designer:fengsui_heg__zhaoe"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhaoe"] = "佚名",
  ["cv:fengsui_heg__zhaoe"] = "暂无",
  ["fengsui_heg__yanshi"] = "言誓",
  [":fengsui_heg__yanshi"] = "<a href='heg__zhongliji'>中立技</a>，每回合各限一次：当你即将受到伤害时，若伤害来源体力值不小于你，你可以展示所有手牌并弃置一种伤害牌牌名的所有牌防止之；你可以将一张伤害牌置于牌堆顶，视为使用或打出一张与原牌合法目标数相同的普通锦囊牌或基本牌。",
  ["fengsui_heg__xinren"] = "衅刃",
  [":fengsui_heg__xinren"] = "锁定技，当你未确定势力时，你的伤害类卡牌不计入手牌上限且无法使用；当你确定势力后，你移除此武将牌；当你移除此武将牌时或首次脱离濒死状态后，你弃置所有手牌并依次使用其中的黑色伤害牌，若此流程中没有角色死亡，你失去1点体力。",
  ["$fengsui_heg__yanshi1"] = "此仇不报，誓不为人。",
  ["$fengsui_heg__yanshi2"] = "言出如刃，誓不可违。",
  ["$fengsui_heg__xinren1"] = "刃饮仇血，方解心恨。",
  ["$fengsui_heg__xinren2"] = "衅鼓而进，一击必杀。",

  ["fengsui_heg__xushao"] = "许劭",
  ["#fengsui_heg__xushao"] = "评天鉴地",
  ["~fengsui_heg__xushao"] = "月旦之评，终成绝响……",
  ["designer:fengsui_heg__xushao"] = "公冶天纵",
  ["illustrator:fengsui_heg__xushao"] = "佚名",
  ["cv:fengsui_heg__xushao"] = "暂无",
  ["fengsui_heg__yingmen"] = "盈门",
  [":fengsui_heg__yingmen"] = "锁定技，当你明置此武将牌后，你将X张势力不同的武将牌置于你的武将牌上（若你已确定势力则去掉势力不同），称为“访客”。回合开始时或你受到伤害后，若你的“访客”数少于X张，则你将“访客”补至X张（X为场上势力数）。",
  ["fengsui_heg__pingjian"] = "评鉴",
  [":fengsui_heg__pingjian"] = "你可以发动“访客”武将牌上的一个无类型或仅有锁定技标签的技能（合法发动时机），然后你移去该“访客”并摸一张牌，若“访客”与你势力相同，你摸两张牌。",
  ["$fengsui_heg__yingmen1"] = "高朋满座，胜友如云。",
  ["$fengsui_heg__yingmen2"] = "天下英才，尽入吾彀。",
  ["$fengsui_heg__pingjian1"] = "月旦品评，一言定乾坤。",
  ["$fengsui_heg__pingjian2"] = "鉴人如鉴玉，优劣自分明。",

  ["fengsui_heg__suoli"] = "索立",
  [":fengsui_heg__suoli"] = "<a href='heg__zhongliji'>中立技</a>，你与其他角色的距离、其他角色与你的距离+X（X为场上已确定势力数）；出牌阶段限一次，你可以将一张装备牌当作【远交近攻】、【联军盛宴】或【戮力同心】使用。",
  ["#fengsui_heg__suoli-choose"] = "索立：选择一张装备牌当作锦囊使用",
  ["fengsui_heg__suoli_remote_attack"] = "远交近攻",
  ["fengsui_heg__suoli_feast"] = "联军盛宴",
  ["fengsui_heg__suoli_work_together"] = "戮力同心",
  ["@fengsui_neutral"] = "中立",
}

return extension
