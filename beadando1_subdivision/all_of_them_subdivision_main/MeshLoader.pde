void loadObjFile(String filename) {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<int[]>();

  String[] lines = loadStrings(filename);
  if (lines == null) {
    println("Hiba: Nem található a megadott OBJ fájl: " + filename + " (a sketch data/ mappájába kell tenni). Beépített kockát használok.");
  } else {
    for (String line : lines) {
      line = line.trim();
      if (line.startsWith("v ")) {
        String[] parts = splitTokens(line, " \t");
        if (parts.length >= 4) {
          vertices.add(new PVector(float(parts[1]), float(parts[2]), float(parts[3])));
        }
      } else if (line.startsWith("f ")) {
        String[] parts = splitTokens(line, " \t");
        if (parts.length >= 4) {
          // A lapokat eredeti alakjukban (háromszög, négyszög, n-szög) tartjuk meg,
          // mert a Catmull-Clark négyszögekkel dolgozik. A Loop/Butterfly maga háromszögel.
          int[] f = new int[parts.length - 1];
          for (int i = 1; i < parts.length; i++) {
            int idx = parseInt(split(parts[i], '/')[0]);
            f[i - 1] = (idx < 0) ? vertices.size() + idx : idx - 1;
          }
          faces.add(f);
        }
      }
    }
  }

  if (vertices.size() == 0 || faces.size() == 0) {
    createDefaultCube();
  }

  // Középre igazítás és méretezés
  PVector sum = new PVector(0, 0, 0);
  for (PVector v : vertices) sum.add(v);
  PVector center = PVector.div(sum, vertices.size());

  float maxDist = 0;
  for (PVector v : vertices) {
    v.sub(center);
    float d = v.mag();
    if (d > maxDist) maxDist = d;
  }

  float targetSize = 150.0;
  if (maxDist > 0) {
    float scaleFactor = targetSize / maxDist;
    for (PVector v : vertices) v.mult(scaleFactor);
  }
}

// Tartalék: egységkocka, kifelé néző (CCW) négyszöglapokkal
void createDefaultCube() {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<int[]>();
  float[][] p = {
    {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
    {-1, -1,  1}, {1, -1,  1}, {1, 1,  1}, {-1, 1,  1}
  };
  for (float[] c : p) vertices.add(new PVector(c[0], c[1], c[2]));
  faces.add(new int[]{0, 3, 2, 1});
  faces.add(new int[]{4, 5, 6, 7});
  faces.add(new int[]{0, 1, 5, 4});
  faces.add(new int[]{3, 7, 6, 2});
  faces.add(new int[]{0, 4, 7, 3});
  faces.add(new int[]{1, 2, 6, 5});
}

ArrayList<PVector> copyVertices(ArrayList<PVector> src) {
  ArrayList<PVector> dest = new ArrayList<PVector>();
  for (PVector v : src) dest.add(v.copy());
  return dest;
}

ArrayList<int[]> copyFaces(ArrayList<int[]> src) {
  ArrayList<int[]> dest = new ArrayList<int[]>();
  for (int[] f : src) dest.add(f.clone());
  return dest;
}
