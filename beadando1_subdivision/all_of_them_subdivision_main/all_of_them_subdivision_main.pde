import java.util.HashMap;
import java.util.HashSet;

// Az aktuálisan megjelenített háló
ArrayList<PVector> vertices;
ArrayList<int[]> faces;

/**
 * Az eredeti (0. szintű) háló, itt tároljuk a háló szerkezetét a beolvasás után,
 * ebből építjük újra a szinteket
 */
ArrayList<PVector> baseVertices;
ArrayList<int[]> baseFaces;

ArrayList<ArrayList<PVector>> levelVertices = new ArrayList<ArrayList<PVector>>();
ArrayList<ArrayList<int[]>> levelFaces = new ArrayList<ArrayList<int[]>>();
int currentLevel = 0;
final int MAX_LEVELS = 4;

// 0 = Catmull-Clark, 1 = Loop, 2 = Butterfly
int algorithm = 0;
String[] algorithmNames = {"Catmull-Clark", "Loop", "Butterfly (+simítás)"};

int renderMode = 0;    // váz -> tömör test + váz -> tömör test
float zoomZ = 200;
float move;            // jobbra, balra mozgás (x tengely)
float rotX, rotY = 0;  // kirajzolt test mozgása
float lastMouseX, lastMouseY; // test mozgatásához kell, hogy ki tudjuk számolni

void setup() {
  size(800, 600, P3D);
  move = width / 2;

  // ablakot a monitor közepére teszi
  surface.setLocation(displayWidth / 2 - width / 2, displayHeight / 2 - height / 2);

/*
 * Mélységteszt (z-buffer). Ennek hatására a közelebbi lapok eltakarják a távolabbiakat,
 * a rajzolás sorrendje pedig nem számít. E nélkül az utoljára rajzolt lap kerülne felülre
 */
  hint(ENABLE_DEPTH_TEST);

  /**
  * Közvetlenül a vertices és faces globális változókat tölti fel
  */
  loadObjFile("cube.obj");
  /**
  * Alaphálót elmentjük
  * Ha csak simán baseVertices = vertices;-t írnánk, akkor csak a referencia másolódna át
  */
  baseVertices = copyVertices(vertices);
  baseFaces = copyFaces(faces);

  /**
  * Kiszámolja az összes subdivision szintet az aktuális algoritmussal
  */
  buildLevels();
}

// Újraszámolja az összes subdivision szintet a kiválasztott algoritmussal
void buildLevels() {
  levelVertices.clear();
  levelFaces.clear();

  vertices = copyVertices(baseVertices);
  faces = copyFaces(baseFaces);
  levelVertices.add(copyVertices(vertices));
  levelFaces.add(copyFaces(faces));

  for (int i = 0; i < MAX_LEVELS; i++) {
    /**
    * applySubdivision() fgv a veritces és faces változókba számolja ki a finomított hálót
    */
    applySubdivision();
    levelVertices.add(copyVertices(vertices));
    levelFaces.add(copyFaces(faces));
  }
  switchLevel(min(currentLevel, levelVertices.size() - 1));
}

void applySubdivision() {
  if (algorithm == 0) {
    applyCatmullClarkSubdivision();
  } else if (algorithm == 1) {
    applyLoopSubdivision();
  } else {
    applyButterflySubdivisionAndSmoothing();
  }
}

void draw() {
  background(20);
  lights();
  pushMatrix();
  translate(move, height / 2, zoomZ);
  rotateX(rotX);
  rotateY(rotY);
  drawModel();
  popMatrix();

  drawUI();
}
