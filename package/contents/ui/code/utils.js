// https://stackoverflow.com/questions/28507619/how-to-create-delay-function-in-qml
function delay(interval, callback, parentItem) {
  let timer = Qt.createQmlObject("import QtQuick; Timer {}", parentItem);
  timer.interval = interval;
  timer.repeat = false;
  timer.triggered.connect(callback);
  timer.triggered.connect(function release() {
    timer.triggered.disconnect(callback);
    timer.triggered.disconnect(release);
    timer.destroy();
  });
  timer.start();
}
