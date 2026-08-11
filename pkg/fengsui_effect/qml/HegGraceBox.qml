import QtQuick
import Fk
import Fk.Components.LunarLTK
import Fk.Pages.LunarLTK
import Fk.Components.Common

GraphicsBox {
  id: root
  property int spacing: 5
  property int currentPlayerId: -1
  property bool operable: false
  property string titleText: Lua.tr("heg__amazing_grace_skill")
  property string promptText: Lua.tr("#heg__amazing_grace_skill")
  property bool allowClose: false
  property var snapshotData: null
  property bool localReplySent: false
  property bool manualInstance: roomScene && roomScene.manualBox
                                && roomScene.manualBox.item === root

  function buildTakerInfo(playerId) {
    if (!playerId) return { general: "", label: "" };
    const info = Lua.evaluate(`(function(id)
      local p = ClientInstance:getPlayerById(id)
      if not p then return nil end
      return {
        general = p.general,
        deputyGeneral = p.deputyGeneral or "",
        seat = p.seat,
      }
    end)(${playerId})`);
    if (!info) return { general: "", label: "" };

    const main = info.general || "anjiang";
    const deputy = info.deputyGeneral || "";
    const mainOk = main !== "anjiang" && main !== "blank_shibing";
    const depOk = deputy !== "" && deputy !== "anjiang"
                  && deputy !== "blank_shibing";
    const soldier = main === "blank_shibing" || deputy === "blank_shibing";

    let display = "anjiang";
    if (mainOk) display = main;
    else if (depOk) display = deputy;
    else if (soldier) display = "blank_shibing";

    let label;
    if (mainOk && depOk) label = `${Lua.tr(main)}/${Lua.tr(deputy)}`;
    else if (mainOk) label = Lua.tr(main);
    else if (depOk) label = Lua.tr(deputy);
    else label = Lua.tr("seat#" + info.seat);
    if (playerId == Self.id) label += Lua.tr("playerstr_self");

    return { general: display, label: label };
  }

  function parseTakenMap(resultList, cardIdSet) {
    const map = {};
    if (!resultList) return map;
    resultList.forEach(pair => {
      let first, second;
      if (Array.isArray(pair) && pair.length >= 2) {
        first = Number(pair[0]);
        second = Number(pair[1]);
      } else if (pair && typeof pair === "object") {
        first = Number(pair.playerId ?? pair.player_id ?? pair.takerId
                       ?? pair.player ?? pair[0]);
        second = Number(pair.cardId ?? pair.card_id ?? pair.cid
                        ?? pair.card ?? pair[1]);
      }
      if (!Number.isFinite(first) || !Number.isFinite(second)) return;
      if (cardIdSet[first]) map[first] = second;
      else if (cardIdSet[second]) map[second] = first;
    });
    return map;
  }

  function applyResults(resultList) {
    const idSet = {};
    for (let i = 0; i < cards.count; i++) idSet[cards.get(i).cid] = true;
    const taken = parseTakenMap(resultList, idSet);
    for (let i = 0; i < cards.count; i++) {
      const item = cards.get(i);
      const tid = taken[item.cid] || 0;
      const info = tid ? buildTakerInfo(tid) : { general: "", label: "" };
      cards.setProperty(i, "takerId", tid);
      cards.setProperty(i, "takerGeneral", info.general);
      cards.setProperty(i, "takerLabel", info.label);
      cards.setProperty(i, "selectable", tid === 0);
    }
  }

  function applyLocalSelect(cardId) {
    if (currentPlayerId <= 0) return;
    for (let i = 0; i < cards.count; i++) {
      const item = cards.get(i);
      if (item.cid === cardId) {
        const info = buildTakerInfo(currentPlayerId);
        cards.setProperty(i, "takerId", currentPlayerId);
        cards.setProperty(i, "takerGeneral", info.general);
        cards.setProperty(i, "takerLabel", info.label);
        cards.setProperty(i, "selectable", false);
        break;
      }
    }
  }

  function buildCards(cardIds, resultList) {
    cards.clear();
    const idSet = {};
    cardIds.forEach(id => { idSet[id] = true; });
    const taken = parseTakenMap(resultList, idSet);
    cardIds.forEach(id => {
      const d = Lua.call("GetCardData", id);
      const tid = taken[id] || 0;
      const info = tid ? buildTakerInfo(tid) : { general: "", label: "" };
      cards.append({
        cid: d.cid ?? id, name: d.name, suit: d.suit, number: d.number,
        mark: d.mark ?? d.marks,
        takerId: tid, takerGeneral: info.general, takerLabel: info.label,
        selectable: tid === 0,
      });
    });
  }

  function buildSnapshotData() {
    const ids = [], res = [];
    for (let i = 0; i < cards.count; i++) {
      const it = cards.get(i);
      ids.push(it.cid);
      if (it.takerId) res.push([it.takerId, it.cid]);
    }
    return {
      cards: ids, results: res,
      currentPlayerId: currentPlayerId, operable: operable,
      title: titleText, prompt: promptText,
    };
  }

  function hasLiveRequest() {
    if (!Backend || !Backend.getRequestData) return false;
    const req = Backend.getRequestData();
    if (!req || typeof req !== "object") return false;
    const total = Number(req.timeout) * 1000;
    if (!Number.isFinite(total) || total <= 0) return false;
    const now = Date.now();
    const ts = Number(req.timestamp ?? now);
    if (!Number.isFinite(ts)) return false;
    return now - ts < total;
  }

  function allCardsLeftProcessing() {
    if (cards.count === 0) return false;
    for (let i = 0; i < cards.count; i++) {
      const cid = cards.get(i).cid;
      const inProcessing = Lua.evaluate(
        `ClientInstance:getCardArea(${cid}) == Card.Processing`
      );
      if (inProcessing) return false;
    }
    return true;
  }

  function clearPassiveActivation() {
    if (
      roomScene.state === "active" &&
      (!operable || localReplySent || !hasLiveRequest())
    ) {
      roomScene.state = "notactive";
    }
  }

  function maybeCloseStaleWindow() {
    if (!manualInstance || allowClose) return;
    if (allCardsLeftProcessing()) {
      doClose();
    }
  }

  title.text: operable ? (promptText || titleText) : titleText
  property int columns: cards.count <= 5 ? cards.count
                                         : Math.ceil(cards.count / 2)
  property int rows: cards.count > columns ? 2 : 1
  property int gridWidth: columns * 93 + spacing * Math.max(0, columns - 1)
  property int gridHeight: rows * 130 + spacing * Math.max(0, rows - 1)
  width: gridWidth + 25
  height: gridHeight + 50

  ListModel { id: cards }

  Grid {
    x: (root.width - root.gridWidth) / 2; y: 35
    columns: root.columns
    columnSpacing: root.spacing; rowSpacing: root.spacing

    Repeater {
      model: cards

      CardItem {
        property var markData: {
          const raw = model.mark;
          if (!raw) return [];
          const arr = [];
          const push = m => {
            if (m && typeof m === "object" && m.k !== undefined)
              arr.push({ k: String(m.k), v: m.v ?? "" });
          };
          if (raw.count !== undefined && typeof raw.get === "function") {
            for (let i = 0; i < raw.count; i++) push(raw.get(i));
          } else if (Array.isArray(raw)) {
            raw.forEach(push);
          } else {
            push(raw);
          }
          return arr;
        }
        cid: model.cid; name: model.name
        suit: model.suit; number: model.number
        mark: markData; markVisible: markData.length > 0
        autoBack: false; selectable: model.selectable
        footnote: ""; footnoteVisible: false

        onClicked: {
          if (root.operable && selectable) {
            root.applyLocalSelect(cid);
            root.operable = false;
            root.localReplySent = true;
            roomScene.state = "notactive";
            ClientInstance.replyToServer("", cid);
          }
        }

        Item {
          anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 4; rightMargin: 4; bottomMargin: 6
          }
          height: 48
          visible: model.takerId !== 0

          Avatar {
            id: takerAvatar
            width: 34; height: 34
            anchors.bottom: parent.bottom
            detailed: false
            general: model.takerGeneral || ""
          }

          Text {
            anchors.right: parent.right; anchors.bottom: parent.bottom
            width: parent.width - takerAvatar.width - 6
            text: model.takerLabel || ""
            color: "#E4D5A0"
            font.family: Config.libianName; font.pixelSize: 12
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WrapAnywhere
          }
        }
      }
    }
  }

  function doClose() {
    allowClose = true;
    root.clearPassiveActivation();
    roomScene.manualBox.source = "";
    root.finished();
  }

  function loadData(data) {
    if (data && !Array.isArray(data) && data.shouldClose) {
      doClose();
      return;
    }

    const isArr = Array.isArray(data);
    const cardIds = isArr ? (data[0] || []) : (data.cards || []);
    const resultList = isArr ? (data[1] || []) : (data.results || []);
    currentPlayerId = isArr ? (data[2] || -1) : (data.currentPlayerId ?? -1);
    operable = isArr ? (data[3] === true) : (data.operable === true);
    if (operable && currentPlayerId === Self.id) {
      localReplySent = false;
    }
    if (!isArr) {
      if (data.title !== undefined) titleText = Lua.tr(data.title);
      if (data.prompt !== undefined) promptText = Lua.tr(data.prompt);
    }

    buildCards(cardIds, resultList);
    snapshotData = buildSnapshotData();
    if (!operable) clearPassiveActivation();

    if (!manualInstance) {
      // popupBox 里的实例只负责转交当前数据包，长期显示由 manualBox 承担
      const forwardData = snapshotData;
      const manualItem = roomScene.manualBox.item;
      if (manualItem && manualItem.updateData) {
        manualItem.updateData(forwardData);
      } else {
        roomScene.manualBox.source =
          AppPath + "/packages/fengsui/pkg/fengsui_effect/qml/HegGraceBox.qml";
        const createdManualItem = roomScene.manualBox.item;
        if (createdManualItem && createdManualItem.loadData)
          createdManualItem.loadData(forwardData);
      }
      root.visible = false;
    }
  }

  function updateData(data) {
    if (data && !Array.isArray(data) && data.shouldClose) {
      doClose();
      return;
    }
    if (!data || (Array.isArray(data) && data.length === 0)) {
      doClose();
      return;
    }

    const isArr = Array.isArray(data);
    const cardIds = isArr ? (data[0] || []) : (data.cards || []);
    const resultList = isArr ? (data[1] || []) : (data.results || []);
    currentPlayerId = isArr ? (data[2] || -1) : (data.currentPlayerId ?? -1);
    operable = isArr ? (data[3] === true) : (data.operable === true);
    if (operable && currentPlayerId === Self.id) {
      localReplySent = false;
    }
    if (!isArr) {
      if (data.title !== undefined) titleText = Lua.tr(data.title);
      if (data.prompt !== undefined) promptText = Lua.tr(data.prompt);
    }

    let sameCards = cardIds.length === cards.count;
    if (sameCards) {
      for (let i = 0; i < cardIds.length; i++) {
        if (cards.get(i).cid !== cardIds[i]) {
          sameCards = false;
          break;
        }
      }
    }
    if (sameCards) {
      applyResults(resultList);
    } else {
      buildCards(cardIds, resultList);
    }
    snapshotData = buildSnapshotData();
    if (!operable) clearPassiveActivation();

    if (!manualInstance) {
      const mi = roomScene.manualBox.item;
      if (mi && mi.updateData) {
        mi.updateData(data);
      } else {
        const forwardData = snapshotData;
        roomScene.manualBox.source =
          AppPath + "/packages/fengsui/pkg/fengsui_effect/qml/HegGraceBox.qml";
        const createdManualItem = roomScene.manualBox.item;
        if (createdManualItem && createdManualItem.loadData)
          createdManualItem.loadData(forwardData);
      }
      if (!operable) clearPassiveActivation();
    }
  }

  onFinished: { }

  Timer {
    interval: 200
    running: root.manualInstance && !root.allowClose
    repeat: true
    onTriggered: {
      root.clearPassiveActivation();
      root.maybeCloseStaleWindow();
    }
  }
}
