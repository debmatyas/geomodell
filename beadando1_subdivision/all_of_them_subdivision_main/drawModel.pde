ArrayList<PVector> faceNormals = new ArrayList<PVector>();
ArrayList<PVector> vertexNormals = new ArrayList<PVector>();

// Lap- és csúcsnormálisok (Newell-módszer, tetszőleges soklapra jó)
void computeNormals() {
  faceNormals = new ArrayList<PVector>();
  vertexNormals = new ArrayList<PVector>();
  for (int i = 0; i < vertices.size(); i++) vertexNormals.add(new PVector(0, 0, 0));

  for (int[] f : faces) {
    PVector n = new PVector(0, 0, 0);
    for (int i = 0; i < f.length; i++) {
      PVector a = vertices.get(f[i]);
      PVector b = vertices.get(f[(i + 1) % f.length]);
      n.x += (a.y - b.y) * (a.z + b.z);
      n.y += (a.z - b.z) * (a.x + b.x);
      n.z += (a.x - b.x) * (a.y + b.y);
    }
    for (int idx : f) vertexNormals.get(idx).add(n); // területtel súlyozott
    n.normalize();
    faceNormals.add(n);
  }
  for (PVector vn : vertexNormals) vn.normalize();
}

PShape modelShape;

// Egyszer felépítjük a hálót PShape-be (szint- vagy megjelenítésmód-váltáskor),
// így rajzoláskor nem kell képkockánként újra elküldeni az összes csúcsot.
void buildModelShape() {
  boolean smooth = (renderMode == 2);
  modelShape = createShape(GROUP);

  PShape tris = createShape();
  tris.beginShape(TRIANGLES);
  applyShapeStyle(tris);
  int triCount = 0;
  for (int i = 0; i < faces.size(); i++) {
    if (faces.get(i).length == 3) { emitFace(tris, i, smooth); triCount++; }
  }
  tris.endShape();
  if (triCount > 0) modelShape.addChild(tris);

  PShape quads = createShape();
  quads.beginShape(QUADS);
  applyShapeStyle(quads);
  int quadCount = 0;
  for (int i = 0; i < faces.size(); i++) {
    if (faces.get(i).length == 4) { emitFace(quads, i, smooth); quadCount++; }
  }
  quads.endShape();
  if (quadCount > 0) modelShape.addChild(quads);

  // Egyéb soklapok külön-külön
  for (int i = 0; i < faces.size(); i++) {
    if (faces.get(i).length > 4) {
      PShape poly = createShape();
      poly.beginShape();
      applyShapeStyle(poly);
      emitFace(poly, i, smooth);
      poly.endShape(CLOSE);
      modelShape.addChild(poly);
    }
  }
}

void applyShapeStyle(PShape s) {
  if (renderMode == 0) {
    s.stroke(0, 255, 200, 160); s.strokeWeight(1); s.fill(30, 100, 180, 120);
  } else if (renderMode == 1) {
    s.stroke(0, 255, 200, 200); s.strokeWeight(1); s.fill(40, 120, 220, 255);
  } else {
    s.noStroke(); s.fill(40, 120, 220, 255);
  }
}

void emitFace(PShape s, int fi, boolean smooth) {
  int[] f = faces.get(fi);
  if (!smooth) {
    PVector n = faceNormals.get(fi);
    s.normal(n.x, n.y, n.z);
  }
  for (int idx : f) {
    if (smooth) {
      PVector vn = vertexNormals.get(idx);
      s.normal(vn.x, vn.y, vn.z);
    }
    PVector p = vertices.get(idx);
    s.vertex(p.x, p.y, p.z);
  }
}

void drawModel() {
  if (modelShape != null) shape(modelShape);
}
