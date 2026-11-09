import java.util.HashMap; // kulcs-érték párok tárolása
import java.util.HashSet; // ismétlődés nélküli elemeket

// ============================================================
// FŐPROGRAM: globális állapot, setup(), szintek felépítése, draw()
// ============================================================

// Az aktuálisan megjelenített háló
// vertices: a csúcsok pozíciói, az index a csúcs azonosítója
// faces: a lapok, minden lap csúcsindexek tömbje (háromszög, négyszög, n-szög)
ArrayList<PVector> vertices;
ArrayList<int[]> faces;

// Az eredeti (0. szintű) háló, ebből építjük újra a szinteket
ArrayList<PVector> baseVertices;
ArrayList<int[]> baseFaces;

// Az összes kiszámolt subdivision szint tárolása (0. szint = eredeti háló)
// levelVertices.get(k) / levelFaces.get(k): a k-adik szint csúcsai és lapjai
ArrayList<ArrayList<PVector>> levelVertices = new ArrayList<ArrayList<PVector>>();
ArrayList<ArrayList<int[]>> levelFaces = new ArrayList<ArrayList<int[]>>();
int currentLevel = 0;          // a most megjelenített szint
final int MAX_LEVELS = 4;      // ennyiszer finomítunk az eredeti hálón

// 0 = Catmull-Clark, 1 = Loop, 2 = Butterfly
int algorithm = 0;
String[] algorithmNames = {"Catmull-Clark", "Loop", "Butterfly (+simítás)"};

// Megjelenítés és kamera állapota
int renderMode = 0;            // 0 = áttetsző háló, 1 = tömör + váz, 2 = sima (csúcsnormálisos)
float zoomZ = 200;             // közelítés (z irányú eltolás)
float move;                    // vízszintes eltolás
float rotX = 0;               // forgatás az x tengely körül
float rotY = 0;               // forgatás az y tengely körül
float lastMouseX, lastMouseY;  // előző egérpozíció a húzás számításához

// Egyszer fut le induláskor: ablak, modell betöltése, szintek kiszámolása
void setup() {
  size(800, 600, P3D);                       // 3D-s ablak
  move = width / 2;                          // a modell az ablak közepére kerül
  surface.setLocation(displayWidth / 2 - width / 2, displayHeight / 2 - height / 2); // ablak a képernyő közepére
  hint(ENABLE_DEPTH_TEST);                   // mélységteszt: a közelebbi lap eltakarja a távolabbit

  loadObjFile("rabbit.obj");                 // OBJ beolvasása a vertices/faces változókba
  baseVertices = copyVertices(vertices);     // az eredeti háló mentése
  baseFaces = copyFaces(faces);

  buildLevels();                             // összes szint kiszámolása
}

// Újraszámolja az összes subdivision szintet a kiválasztott algoritmussal
void buildLevels() {
  levelVertices.clear();
  levelFaces.clear();

  // kiindulás az eredeti hálóból, ez lesz a 0. szint
  vertices = copyVertices(baseVertices);
  faces = copyFaces(baseFaces);
  levelVertices.add(copyVertices(vertices));
  levelFaces.add(copyFaces(faces));

  // minden kör az előző szintet finomítja, az eredményt eltároljuk
  for (int i = 0; i < MAX_LEVELS; i++) {
    applySubdivision();
    levelVertices.add(copyVertices(vertices));
    levelFaces.add(copyFaces(faces));
  }
  // átváltás a megjelenítendő szintre (a szint nem változik algoritmusváltáskor)
  switchLevel(min(currentLevel, levelVertices.size() - 1));
}

// A kiválasztott algoritmus egy lépését futtatja az aktuális vertices/faces hálón
void applySubdivision() {
  if (algorithm == 0) {
    applyCatmullClarkSubdivision();
  } else if (algorithm == 1) {
    applyLoopSubdivision();
  } else {
    applyButterflySubdivisionAndSmoothing();
  }
}

// Minden képkockánál lefut: kép törlése, modell elhelyezése és kirajzolása, UI
void draw() {
  background(20);   // sötét háttér, törli az előző képkockát
  lights();         // alapértelmezett megvilágítás

  pushMatrix();                          // a transzformációk csak a modellre hatnak
  translate(move, height / 2, zoomZ);    // modell a képernyő közepére, zoom
  rotateX(rotX);                         // forgatás az egérhúzás szerint
  rotateY(rotY);
  drawModel();                           // a kész PShape kirajzolása
  popMatrix();

  drawUI();                              // szöveges felület a modell fölött
}
