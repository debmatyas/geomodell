void loadOBJ(String filename) {
  baseVertices = new ArrayList<PVector>();
  baseFaces = new ArrayList<ArrayList<Integer>>();

  String[] lines = loadStrings(filename);
  if (lines == null) {
    println("Hiba: Nem található a fájl: " + filename);
    return;
  }

  for (String line : lines) {
    line = line.trim();
    if (line.startsWith("v ")) {
      String[] parts = line.split("\\s+");
      float x = float(parts[1]);
      float y = float(parts[2]);
      float z = float(parts[3]);
      baseVertices.add(new PVector(x, y, z));
    } else if (line.startsWith("f ")) {
      String[] parts = line.split("\\s+");
      ArrayList<Integer> face = new ArrayList<Integer>();
      for (int i = 1; i < parts.length; i++) {
        String[] indices = parts[i].split("/");
        int vIndex = Integer.parseInt(indices[0]) - 1;
        face.add(vIndex);
      }
      
      // Loop subdivision miatt a poligonokat automatikusan háromszögekre bontjuk (Triangulation)
      if (face.size() == 3) {
        baseFaces.add(face);
      } else if (face.size() == 4) {
        // Quad felbontása 2 háromszögre
        ArrayList<Integer> t1 = new ArrayList<Integer>();
        t1.add(face.get(0)); t1.add(face.get(1)); t1.add(face.get(2));
        baseFaces.add(t1);
        ArrayList<Integer> t2 = new ArrayList<Integer>();
        t2.add(face.get(0)); t2.add(face.get(2)); t2.add(face.get(3));
        baseFaces.add(t2);
      } else if (face.size() > 4) {
        int v0 = face.get(0);
        for (int i = 1; i < face.size() - 1; i++) {
          ArrayList<Integer> t = new ArrayList<Integer>();
          t.add(v0);
          t.add(face.get(i));
          t.add(face.get(i + 1));
          baseFaces.add(t);
        }
      }
    }
  }

  centerAndScaleModel();
}

void centerAndScaleModel() {
  if (baseVertices.isEmpty()) return;

  PVector center = new PVector(0, 0, 0);
  for (PVector v : baseVertices) {
    center.add(v);
  }
  center.div(baseVertices.size());

  for (PVector v : baseVertices) {
    v.sub(center);
  }

  float maxDist = 0;
  for (PVector v : baseVertices) {
    float d = v.mag();
    if (d > maxDist) maxDist = d;
  }

  if (maxDist > 0) {
    float scaleFactor = 150.0f / maxDist;
    for (PVector v : baseVertices) {
      v.mult(scaleFactor);
    }
  }
}
