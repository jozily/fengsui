import QtQuick

Item {
  id: root
  // 建国.BB
  //property int sceneHeight: 720
  //property int sceneWidth: 1280
  property string img: "../image/BuildCountry/"
  //素材文件夹

  anchors.fill: parent
  scale: 1

  Image {
    id: bg
    anchors.centerIn: parent
    scale: 1.5
    fillMode: Image.Tile
    source: img + "BuildCountry" + curr + ".png"
    property int curr: 0
    opacity: 1
  }

  //静态
  ParallelAnimation {
    id: step1
    running: true

    SequentialAnimation {
          PauseAnimation { duration: 50 }
          ScriptAction { script: bg.opacity = 1; }
          PropertyAnimation {
            target: bg
            property: "curr"
            to: 49
            duration: 3000
          }
        }
    onFinished: {
      anim2.start();
    }
  }

  PropertyAnimation {
     id: anim2
     target: root
     property: "opacity"
     to: 0
     duration: 560
     onFinished: {
       roomScene.bigAnim.source = "";
     }
   }
}
