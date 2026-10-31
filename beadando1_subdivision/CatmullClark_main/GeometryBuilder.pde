// A PShape felépítése (Háromszögelve a GPU számára)
void updateMeshShape() {
  meshShape = createShape();
  meshShape.beginShape(TRIANGLES);
  
  if (showWireframe) {
    meshShape.stroke(100, 200, 255);
  } else {
    meshShape.noStroke();
  }
  meshShape.fill(40, 90, 140, 220);

  for (ArrayList<Integer> f : currentFaces) {
    int size = f.size();
    if (size == 4) {
      // Quad feldarabolása 2 darab háromszögre
      int v0 = f.get(0);
      int v1 = f.get(1);
      int v2 = f.get(2);
      int v3 = f.get(3);
      
      addVert(v0); addVert(v1); addVert(v2);
      addVert(v0); addVert(v2); addVert(v3);
    } else if (size == 3) {
      addVert(f.get(0)); addVert(f.get(1)); addVert(f.get(2));
    } else {
      // Általános poligon fan trianguláció
      int v0 = f.get(0);
      for (int i = 1; i < size - 1; i++) {
        addVert(v0);
        addVert(f.get(i));
        addVert(f.get(i + 1));
      }
    }
  }
  meshShape.endShape();
}

void addVert(int idx) {
  PVector v = currentVertices.get(idx);
  meshShape.vertex(v.x, v.y, v.z);
}
