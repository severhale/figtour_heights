class Edge {
  float maxForce = (zMax/25);
  
  float c = sqrt(maxForce);
  public Node p1, p2;
  public Edge(Node p1, Node p2) {
    this.p1 = p1;
    this.p2 = p2;
  }
  
  public Intersection getIntersection(Edge e) {
    if (e.p1 == p2 || e.p2 == p1 || e.p1 == p1 || e.p2 == p2) {
      return null;
    }
    PVector q = e.p1.p;
    PVector p = p1.p;
    PVector s = PVector.sub(e.p2.p, e.p1.p);
    PVector r = PVector.sub(p2.p, p1.p);
    float t = cross(PVector.sub(q, p), s) / cross(r, s);
    float u = cross(PVector.sub(p, q), r) / cross(s, r);
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return new Intersection(this, e, t, u);
    }
    else {
      return null;
    }
  }
  
  public float repelFrom(Edge e) {
    maxForce = (zMax / 25);
    c = map(mouseY, 0, height, .1, 10);
    
    if (e.p1 == p2 || e.p2 == p1) {
      return -1;
    }
    PVector q = e.p1.p;
    PVector p = p1.p;
    PVector s = PVector.sub(e.p2.p, e.p1.p);
    PVector r = PVector.sub(p2.p, p1.p);
    float t = cross(PVector.sub(q, p), s) / cross(r, s);
    float u = cross(PVector.sub(p, q), r) / cross(s, r);
    float dz = -1;
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      PVector intersection1 = PVector.lerp(p1.p, p2.p, t);
      PVector intersection2 = PVector.lerp(e.p1.p, e.p2.p, u); 
      
      //line(intersection1, intersection2);
      
      dz = intersection1.z - intersection2.z;
      if (abs(dz)<.01) {
        dz = random(-.1, .1);
      }
      float forceLength = 0;
      if (dz > 0) {
        forceLength = min(maxForce, c/(dz * dz));
        if (forceLength == maxForce) {
          println("MAXED");
        }
      }
      else if (dz < 0) {
        forceLength = max(-maxForce, c/(dz * (-dz)));
        if (forceLength == -maxForce) {
          println("MINNED");
        }
      }
      
      p2.applyZForce(forceLength * t);
      p1.applyZForce(forceLength * (1 - t));
    }
    return dz;
  }
  
  float cross(PVector v, PVector w) {
    return v.x * w.y - v.y * w.x;
  }
}