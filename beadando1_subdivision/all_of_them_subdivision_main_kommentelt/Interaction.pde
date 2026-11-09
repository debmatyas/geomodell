// ============================================================
// INTERACTION: szöveges felület, egér, billentyűk, szintváltás
// ============================================================

// A bal felső sarokban megjelenő szöveges felület
void drawUI() {
  hint(DISABLE_DEPTH_TEST);   // a szöveg mindig a modell fölött látszik
  pushMatrix();
  camera();                   // alapkamera: az (x, y) koordináták pixelek
  noLights();                 // a szöveg színe ne függjön a fénytől

  fill(255);
  textSize(16);
  int textY = 40;             // az első sor függőleges pozíciója
  // állapotkijelzés: algoritmus, szint, lapok száma
  text("Algoritmus: " + algorithmNames[algorithm], 30, textY);
  text("Subdivision szint: " + currentLevel + "  (lapok: " + faces.size() + ")", 30, textY + 25);
  // súgó a vezérléshez
  text("1-es / 2-es gomb: Szint növelés / csökkentés", 30, textY + 55);
  text("3-as gomb: Háló / Sima / Csúcsnormálisos felület váltás", 30, textY + 80);
  text("4-es gomb: Algoritmus váltás (Catmull-Clark / Loop / Butterfly)", 30, textY + 105);
  text("Fel/Le nyíl: Közelítés / Távolodás, Bal/Jobb: eltolás", 30, textY + 130);
  text("Forgatás: kattints és húzd az egeret", 30, textY + 155);

  popMatrix();
  hint(ENABLE_DEPTH_TEST);    // a modell rajzolásához újra kell a mélységteszt
}

// Egérgomb lenyomásakor elmenti a kiindulási pozíciót
void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

// Húzás közben az egér elmozdulásából forgatást számol
void mouseDragged() {
  rotY += (mouseX - lastMouseX) * 0.01;   // vízszintes húzás: forgatás az y tengely körül
  rotX -= (mouseY - lastMouseY) * 0.01;   // függőleges húzás: forgatás az x tengely körül
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

// Billentyűkezelés
void keyPressed() {
  if (key == '1') {
    // következő (finomabb) szint, ha van még
    if (currentLevel < levelVertices.size() - 1) switchLevel(currentLevel + 1);
  } else if (key == '2') {
    // előző (durvább) szint, ha van még
    if (currentLevel > 0) switchLevel(currentLevel - 1);
  } else if (key == '3') {
    // megjelenítési mód váltása, az alakzatot újra kell építeni (más stílus, más normálisok)
    renderMode = (renderMode + 1) % 3;
    buildModelShape();
  } else if (key == '4') {
    // következő algoritmus, az összes szint újraszámolása
    algorithm = (algorithm + 1) % algorithmNames.length;
    buildLevels();
  } else if (key == CODED) {
    // nyílbillentyűk: kamera
    if (keyCode == UP) {
      zoomZ += 30;      // közelítés
    } else if (keyCode == DOWN) {
      zoomZ -= 30;      // távolodás
    } else if (keyCode == LEFT) {
      move += 15;       // eltolás
    } else if (keyCode == RIGHT) {
      move -= 15;
    }
  }
}

// Átvált egy eltárolt szintre: beállítja a hálót, újraszámolja a normálisokat, felépíti az alakzatot
void switchLevel(int lvl) {
  currentLevel = lvl;
  vertices = levelVertices.get(lvl);
  faces = copyFaces(levelFaces.get(lvl));
  computeNormals();      // előbb a normálisok...
  buildModelShape();     // ...mert az alakzat felépítése ezeket használja
}
