void loadObjFile(String filename) {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<int[]>();
  
  String[] lines = loadStrings(filename);
  if (lines == null) {
    println("Hiba: Nem található a megadott OBJ fájl: " + filename);
    return;
  }
  
  for (String line : lines) {
    line = line.trim();
    if (line.startsWith("v ")) {
      String[] parts = splitTokens(line, " ");
      if (parts.length >= 4) {
        vertices.add(new PVector(float(parts[1]), float(parts[2]), float(parts[3])));
      }
    } else if (line.startsWith("f ")) {
      String[] parts = splitTokens(line, " ");
      if (parts.length >= 4) {
        int i0 = parseInt(split(parts[1], '/')[0]) - 1;
        int i1 = parseInt(split(parts[2], '/')[0]) - 1;
        int i2 = parseInt(split(parts[3], '/')[0]) - 1;
        faces.add(new int[]{i0, i1, i2});
        
        if (parts.length >= 5) {
          int i3 = parseInt(split(parts[4], '/')[0]) - 1;
          faces.add(new int[]{i0, i2, i3});
        }
      }
    }
  }
  
  if (vertices.size() > 0) {
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
