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
      baseFaces.add(face);
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
