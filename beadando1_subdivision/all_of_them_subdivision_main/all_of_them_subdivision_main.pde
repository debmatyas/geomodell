import java.util.HashMap;
import java.util.HashSet;

// Az aktuálisan megjelenített háló
ArrayList<PVector> vertices;
ArrayList<int[]> faces;

// Az eredeti (0. szintű) háló, ebből építjük újra a szinteket
ArrayList<PVector> baseVertices;
ArrayList<int[]> baseFaces;

ArrayList<ArrayList<PVector>> levelVertices = new ArrayList<ArrayList<PVector>>();
ArrayList<ArrayList<int[]>> levelFaces = new ArrayList<ArrayList<int[]>>();
int currentLevel = 0;
final int MAX_LEVELS = 4;

// 0 = Catmull-Clark, 1 = Loop, 2 = Butterfly
int algorithm = 0;
String[] algorithmNames = {"Catmull-Clark", "Loop", "Butterfly (+simítás)"};

int renderMode = 0;
float zoomZ = 200;
float move;
float rotX = 0;
float rotY = 0;
float lastMouseX, lastMouseY;

void setup() {
  size(800, 600, P3D);
  move = width / 2;
  surface.setLocation(displayWidth / 2 - width / 2, displayHeight / 2 - height / 2);
  hint(ENABLE_DEPTH_TEST);

  loadObjFile("beetle.obj");
  baseVertices = copyVertices(vertices);
  baseFaces = copyFaces(faces);

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
