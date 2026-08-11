import QtQuick

Item {
  id: root
  // 先驱特效.BB
  //property int sceneHeight: 720
  //property int sceneWidth: 1280
  property string img: "../image/Effect/Command/"
  //素材文件夹

  anchors.fill: parent
  scale: 1

  Image {
    id: bg
    anchors.centerIn: parent
    fillMode: Image.PreserveAspectFit //保持宽高比
    scale: 0.7
    source: img + "Command" + curr + ".png"
    property int curr: 0
    opacity: 1
  }

  //静态
  ParallelAnimation {
    id: step1
    running: true

    SequentialAnimation {
          PauseAnimation { duration: 100 }
          ScriptAction { script: bg.opacity = 1; }
          PropertyAnimation {
            target: bg
            property: "curr"
            to: 25
            duration: 1500
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
