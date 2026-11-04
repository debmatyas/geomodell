void drawUI() {
  hint(DISABLE_DEPTH_TEST);
  pushMatrix();
  camera();
  noLights();

  fill(255);
  textSize(16);
  int textY = 40;
  text("Algoritmus: " + algorithmNames[algorithm], 30, textY);
  text("Subdivision szint: " + currentLevel + "  (lapok: " + faces.size() + ")", 30, textY + 25);
  text("1-es / 2-es gomb: Szint növelés / csökkentés", 30, textY + 55);
  text("3-as gomb: Háló / Sima / Csúcsnormálisos felület váltás", 30, textY + 80);
  text("4-es gomb: Algoritmus váltás (Catmull-Clark / Loop / Butterfly)", 30, textY + 105);
  text("Fel/Le nyíl: Közelítés / Távolodás, Bal/Jobb: eltolás", 30, textY + 130);
  text("Forgatás: kattints és húzd az egeret", 30, textY + 155);

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
    buildModelShape();
  } else if (key == '4') {
    algorithm = (algorithm + 1) % algorithmNames.length;
    buildLevels();
  } else if (key == CODED) {
    if (keyCode == UP) {
      zoomZ += 30;
    } else if (keyCode == DOWN) {
      zoomZ -= 30;
    } else if (keyCode == LEFT) {
      move += 15;
    } else if (keyCode == RIGHT) {
      move -= 15;
    }
  }
}

void switchLevel(int lvl) {
  currentLevel = lvl;
  vertices = levelVertices.get(lvl);
  faces = copyFaces(levelFaces.get(lvl));
  computeNormals();
  buildModelShape();
}
