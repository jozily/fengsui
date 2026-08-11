// SPDX-License-Identifier: GPL-3.0-or-later

// 暂时用utility里的代替

import QtQuick
import QtQuick.Layouts
import Fk
import LunarLtk.Pages.Popups
import LunarLtk
import LunarLtk.Components
import Fk.Components.Common

import "../../../../utility/qml/models"

GraphicsBox {
  id: root

  required property ChooseGeneralsAndChoiceModel dataModel

  title.text: Ltk.processPrompt(dataModel.prompt)
  width: generalArea.width + body.anchors.leftMargin + body.anchors.rightMargin
  height: body.implicitHeight + body.anchors.topMargin + body.anchors.bottomMargin

  Column {
    id: body
    anchors.fill: parent
    anchors.margins: 40
    anchors.bottomMargin: 20

    GridView {
      id: generalArea
      width: 200
      height: 150
      cellWidth: 93 + 5
      cellHeight: 130 + 5
      model: dataModel.cards

      delegate: GeneralCardItem {
        id: gItem
        required property string modelData

        dataModel: Ltk.createGeneralCardModel(modelData)
        selectable: !root.dataModel.disable_cards.includes(modelData)
        autoBack: false
        //hasCompanion: Ltk.isCompanionWith(root.dataModel.cards[0], root.dataModel.cards[1])

        onSelectedChanged: {
          if (selected) {
            chosenInBox = true;
            root.dataModel.toggleGeneral(modelData, selected);
          } else {
            chosenInBox = false;
            root.dataModel.toggleGeneral(modelData, false);
          }
        }
        Connections {
          target: root.dataModel
          function onRequestGeneralUnselect(name) {
            if (name === modelData)
              selected = false;
          }
        }
        onRightClicked: {
          root.parent.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"), {
            generals: [modelData]
          });
        }
      }
    }

    Item {
      id: buttonArea
      width: parent.width
      height: 40

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 8

        MetroButton {
          id: fightButton
          text: Lua.tr("OK")
          width: 120
          height: 35
          enabled: true

          onClicked: {
            root.dataModel.doAccepted("OK");
          }
        }

        MetroButton {
          id: detailBtn
          text: Lua.tr("Show General Detail")
          onClicked: root.parent.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"), {
            generals: [dataModel.cards[0], dataModel.cards[1]]
          });
        }
      }
    }
  }
}
