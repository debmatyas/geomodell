void keyPressed() {
  if (key == '1') {
    subLevel = constrain(subLevel + 1, 0, 4);
    rebuildMesh();
    redraw();
  } else if (key == '2') {
    subLevel = constrain(subLevel - 1, 0, 4);
    rebuildMesh();
    redraw();
  } else if (key == '3') {
    showWireframe = !showWireframe;
    updateMeshShape(); // Frissítjük a háló megjelenítést a PShape-en belül is
    redraw();
  } else if (key == CODED) {
    if (keyCode == UP) {
      zoom += 0.1f;
      redraw();
    } else if (keyCode == DOWN) {
      zoom = max(0.1f, zoom - 0.1f);
      redraw();
    }
  }
}

void mouseDragged() {
  float dx = mouseX - pmouseX;
  float dy = mouseY - pmouseY;
  rotY += dx * 0.01f;
  rotX -= dy * 0.01f;
  
  redraw(); // A PShape miatt villámgyors renderelés
}
