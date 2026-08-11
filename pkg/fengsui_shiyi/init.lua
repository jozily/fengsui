local extension = Package:new("fengsui_shiyi")
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_shiyi/skills")
assert(#extension.skill_skels == 10, "fengsui_shiyi must load exactly 10 skill skeletons")

local xinxianying = General:new(extension, "fengsui_heg__xinxianying", "wei", 3, 3, General.Female)
xinxianying:addSkills { "fengsui_heg__qingshi", "fengsui_heg__jiejie" }

local guotu = General:new(extension, "fengsui_heg__guotu", "qun", 3)
guotu:addSkills { "fengsui_heg__qushi", "fengsui_heg__weijie" }

local sunluban = General:new(extension, "fengsui_heg__sunluban", "wu", 3, 3, General.Female)
sunluban:addSkills { "fengsui_heg__zenhui", "fengsui_heg__jiaojin" }

local wangyi = General:new(extension, "fengsui_heg__wangyi", "wei", 3, 3, General.Female)
wangyi:addSkills { "fengsui_heg__zhenlie", "fengsui_heg__miji" }

local simayou = General:new(extension, "SP_heg__simayou", "jin", 3)
simayou:addSkills { "heg__fuzheng", "heg__yunde" }
simayou:addCompanions("fengsui_heg__jiabao")

Fk:loadTranslationTable{
  ["fengsui_shiyi"] = "烽燧燎原-拾遗",

  ["fengsui_heg__xinxianying"] = "辛宪英",
  ["#fengsui_heg__xinxianying"] = "明鉴惠识",
  ["illustrator:fengsui_heg__xinxianying"] = "佚名",
  ["$fengsui_heg__qingshi1"] = "会在事纵恣，非持久处下之道。",
  ["$fengsui_heg__qingshi2"] = "智多而肆，吾畏其有他志。",
  ["$fengsui_heg__jiejie1"] = "职守，人之大义也，安可不出？",
  ["$fengsui_heg__jiejie2"] = "为人执鞭而弃其事，不祥，不可也。",
  ["~fengsui_heg__xinxianying"] = "吾一生明鉴，竟错看于你。",

  ["fengsui_heg__guotu"] = "郭图",
  ["#fengsui_heg__guotu"] = "凶臣",
  ["illustrator:fengsui_heg__guotu"] = "厦门塔普",
  ["$fengsui_heg__qushi1"] = "将军天人之姿，可令四海归心。",
  ["$fengsui_heg__qushi2"] = "小小锦上之花，难表一腔敬意。",
  ["$fengsui_heg__weijie1"] = "败战之罪在你，休要多言！",
  ["$fengsui_heg__weijie2"] = "纵汝舌灿莲花，亦难逃死罪。",
  ["~fengsui_heg__guotu"] = "工于心计而不成事，匹夫怀其罪……",

  ["fengsui_heg__sunluban"] = "孙鲁班",
  ["#fengsui_heg__sunluban"] = "为虎作伥",
  ["illustrator:fengsui_heg__sunluban"] = "鬼画府",
  ["$fengsui_heg__zenhui1"] = "本公主说你忤逆，岂能有假？",
  ["$fengsui_heg__zenhui2"] = "不用挣扎了，你们谁都逃不了！",
  ["$fengsui_heg__jiaojin1"] = "狂妄之徒！忘了你自己的身份了吗？",
  ["$fengsui_heg__jiaojin2"] = "和本公主比心机谋算？哼，可笑！",
  ["~fengsui_heg__sunluban"] = "妹妹，姐姐是迫不得已……",

  ["fengsui_heg__wangyi"] = "王异",
  ["#fengsui_heg__wangyi"] = "决意的巾帼",
  ["illustrator:fengsui_heg__wangyi"] = "佚名",
  ["$fengsui_heg__zhenlie1"] = "虽是妇人，亦当奋身一搏！",
  ["$fengsui_heg__zhenlie2"] = "为雪前耻，不惜吾身！",
  ["$fengsui_heg__miji1"] = "此计，可歼敌精锐！",
  ["$fengsui_heg__miji2"] = "此举，可破敌之围！",
  ["~fengsui_heg__wangyi"] = "去年花开君还在，今年花落复谁在。",

  ["SP_heg__simayou"] = "司马攸",
  ["SP_heg"] = "SP系列",
  ["#SP_heg__simayou"] = "舞阳侯",
  ["designer:SP_heg__simayou"] = "时时六&雪人学长",
  ["$heg__fuzheng_SP_heg__simayou1"] = "承景王之嗣，当佐宗室以安社稷。",
  ["$heg__fuzheng_SP_heg__simayou2"] = "宗亲有难，攸岂可袖手旁观。",
  ["$heg__fuzheng_SP_heg__simayou3"] = "辅弼朝纲，所念唯国，不计私门。",
  ["$heg__fuzheng_SP_heg__simayou4"] = "愿移此位，换宗室一脉得安。",
  ["$heg__yunde_SP_heg__simayou1"] = "德不独善，当分惠于宗亲。",
  ["$heg__yunde_SP_heg__simayou2"] = "知人而后任之，量才而后授之。",
  ["$heg__yunde_SP_heg__simayou3"] = "兄弟同心，何必以储位相疑。",
  ["$heg__yunde_SP_heg__simayou4"] = "进不争权，退不避责，此为臣节。",
  ["~SP_heg__simayou"] = "臣弟别无他志，陛下何以疑我至此……",
}

assert(#extension.generals == 5, "fengsui_shiyi must register exactly 5 generals")

return extension
