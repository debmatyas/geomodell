void drawModel() {
  pushStyle();
  if (renderMode == 0) {
    stroke(0, 255, 200, 160); strokeWeight(1); fill(30, 100, 180, 120);
  } else if (renderMode == 1) {
    stroke(0, 255, 200, 200); strokeWeight(1); fill(40, 120, 220, 255);
  } else {
    noStroke(); fill(40, 120, 220, 255);
  }
  
  beginShape(TRIANGLES);
  for (int[] f : faces) {
    PVector v1 = vertices.get(f[0]), v2 = vertices.get(f[1]), v3 = vertices.get(f[2]);
    vertex(v1.x, v1.y, v1.z);
    vertex(v2.x, v2.y, v2.z);
    vertex(v3.x, v3.y, v3.z);
  }
  endShape();
  popStyle();
}

void drawUI() {
  hint(DISABLE_DEPTH_TEST);
  pushMatrix();
  camera();
  noLights();
  
  fill(255);
  textSize(16);
  int textY = 40;
  text("Subdivision szint: " + currentLevel, 30, textY);
  text("1-es / 2-es gomb: Szint növelés / csökkentés", 30, textY + 30);
  text("3-as gomb: Háló / Sima felület váltás", 30, textY + 60);
  text("Fel/Le nyíl: Közelítés / Távolodás", 30, textY + 90);
  text("Forgatás: kattints és húzd az egeret", 30, textY + 120);
  
  popMatrix();
  hint(ENABLE_DEPTH_TEST);
}

void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void mouseDragged() {
  rotY += (mouseX - lastMouseX) * 0.01;
  rotX -= (mouseY - lastMouseY) * 0.01;
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void keyPressed() {
  if (key == '1') {
    if (currentLevel < levelVertices.size() - 1) switchLevel(currentLevel + 1);
  } else if (key == '2') {
    if (currentLevel > 0) switchLevel(currentLevel - 1);
  } else if (key == '3') {
    renderMode = (renderMode + 1) % 3;
  } else if (key == CODED) {
    if (keyCode == UP){
      zoomZ += 30;
    } else if (keyCode == DOWN){
      zoomZ -= 30;
    } else if (keyCode == LEFT){
      move += 15;
    } else if (keyCode == RIGHT){
      move -= 15;
    }
  }
}

void switchLevel(int lvl) {
  currentLevel = lvl;
  vertices = copyVertices(levelVertices.get(lvl));
  faces = copyFaces(levelFaces.get(lvl));
}
