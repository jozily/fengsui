-- 学园都市组皮肤包。只提供立绘外观，不含武将、技能与卡牌。
-- 皮肤名就是 image/skins 目录下的文件名；界面显示的是以文件名为键的翻译条目，
-- 因此文件名保持英文、显示名可以随意改中文，两者互不影响。
local extension = Package:new("fengsui_skins", Package.SkinPack)
extension.extensionName = "fengsui"

local SKINS = {
  {
    generals = { "fengsui_toaru__heg__saten" },
    files = {
      "fengsui_toaru__heg__saten_s1.jpg",
      "fengsui_toaru__heg__saten_s2.jpg",
      "fengsui_toaru__heg__saten_s3.jpg",
    },
  },
  {
    generals = { "fengsui_toaru__heg__misaka" },
    files = {
      "fengsui_toaru__heg__misaka_s1.jpg",
      "fengsui_toaru__heg__misaka_s2.jpg",
      "fengsui_toaru__heg__misaka_s3.jpg",
      "fengsui_toaru__heg__misaka_s4.jpg",
      "fengsui_toaru__heg__misaka_s5.jpg",
    },
  },
  {
    generals = { "fengsui_toaru__heg__shirai" },
    files = {
      "fengsui_toaru__heg__shirai_s1.jpg",
      "fengsui_toaru__heg__shirai_s2.jpg",
      "fengsui_toaru__heg__shirai_s3.jpg",
    },
  },
  {
    generals = { "fengsui_toaru__heg__shokuhou" },
    files = {
      "fengsui_toaru__heg__shokuhou_s1.jpg",
      "fengsui_toaru__heg__shokuhou_s2.jpg",
      "fengsui_toaru__heg__shokuhou_s3.jpg",
    },
  },
  {
    generals = { "fengsui_toaru__heg__frenda" },
    files = {
      "fengsui_toaru__heg__frenda_s1.jpg",
      "fengsui_toaru__heg__frenda_s2.jpg",
      "fengsui_toaru__heg__frenda_s3.jpg",
    },
  },
  {
    generals = { "fengsui_heg__lemin" },
    files = {
      "fengsui_heg__lemin_s1.jpg",
    },
  },
  {
    generals = { "heg__simaying" },
    files = {
      "heg__simaying_s1.jpg",
    },
  },
  {
    generals = { "fengsui_heg__xuncan" },
    files = {
      "fengsui_heg__xuncan_s1.jpg",
    },
  },
  {
    generals = { "fengsui_heg__caocen" },
    files = {
      "fengsui_heg__caocen_s1.jpg",
    },
  },
  {
    generals = { "fengsui_heg__kuaishi" },
    files = {
      "fengsui_heg__kuaishi_s1.jpg",
    },
  },
  {
    generals = { "heg__sunxiuj" },
    files = {
      "heg__sunxiuj_s1.jpg",
    },
  },
  {
    generals = { "fengsui_heg__hanshou" },
    files = {
      "fengsui_heg__hanshou_s1.jpg",
    },
  },
  {
    generals = { "fengsui_heg__jiawu" },
    files = {
      "fengsui_heg__jiawu_s1.jpg",
    },
  },
}

local content = {}
for _, item in ipairs(SKINS) do
  table.insert(content, {
    enabled_generals = item.generals,
    skins = item.files,
  })
end

extension:addSkinPackage {
  path = "/image/skins",
  content = content,
}

Fk:loadTranslationTable {
  ["fengsui_skins"] = "烽燧燎原-皮肤",

  ["fengsui_toaru__heg__saten_s1.jpg"] = "清凉夏日",
  ["fengsui_toaru__heg__saten_s2.jpg"] = "休憩午后",
  ["fengsui_toaru__heg__saten_s3.jpg"] = "守护者",

  ["fengsui_toaru__heg__misaka_s1.jpg"] = "level.6",
  ["fengsui_toaru__heg__misaka_s2.jpg"] = "放学以后",
  ["fengsui_toaru__heg__misaka_s3.jpg"] = "御坂辣妹",
  ["fengsui_toaru__heg__misaka_s4.jpg"] = "跃动",
  ["fengsui_toaru__heg__misaka_s5.jpg"] = "守护者",

  ["fengsui_toaru__heg__shirai_s1.jpg"] = "妖精之翼",
  ["fengsui_toaru__heg__shirai_s2.jpg"] = "凛冽之梦",
  ["fengsui_toaru__heg__shirai_s3.jpg"] = "风纪委员",

  ["fengsui_toaru__heg__shokuhou_s1.jpg"] = "体育课",
  ["fengsui_toaru__heg__shokuhou_s2.jpg"] = "粉色黄昏",
  ["fengsui_toaru__heg__shokuhou_s3.jpg"] = "初诣",

  ["fengsui_toaru__heg__frenda_s1.jpg"] = "贝雷少女",
  ["fengsui_toaru__heg__frenda_s2.jpg"] = "人偶少女",
  ["fengsui_toaru__heg__frenda_s3.jpg"] = "火箭少女",

  ["fengsui_heg__lemin_s1.jpg"] = "紫藤倚怀",
  ["heg__simaying_s1.jpg"] = "紫藤相护",

  ["fengsui_heg__xuncan_s1.jpg"] = "此情眷天地",
  ["fengsui_heg__caocen_s1.jpg"] = "此情眷天地",

  ["fengsui_heg__kuaishi_s1.jpg"] = "挽君梦",
  ["heg__sunxiuj_s1.jpg"] = "别重天",

  ["fengsui_heg__hanshou_s1.jpg"] = "与香逢",
  ["fengsui_heg__jiawu_s1.jpg"] = "与香逢",
}

return extension
