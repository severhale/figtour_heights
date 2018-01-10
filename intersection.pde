class Intersection {
  public Edge e1, e2;
  public float t, u;
  public Intersection(Edge e1, Edge e2, float t, float u) {
    this.e1 = e1;
    this.e2 = e2;
    this.t = t;
    this.u = u;
  }
  public void applyForce() {
    float maxForce = (zMax / 25);
    float c = 3;
    // float c = map(mouseY, 0, height, .1, 10);
    // c = c*c;
    PVector intersection1 = PVector.lerp(e1.p1.p, e1.p2.p, t);
    PVector intersection2 = PVector.lerp(e2.p1.p, e2.p2.p, u);

    //line(intersection1, intersection2);

    float dz = intersection1.z - intersection2.z;
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

    e1.p2.applyZForce(forceLength * t);
    e1.p1.applyZForce(forceLength * (1 - t));

    e2.p2.applyZForce(-forceLength * u);
    e2.p1.applyZForce(-forceLength * (1 - u));
  }
  public float getDistance() {
    float z1 = lerp(e1.p1.p.z, e1.p2.p.z, t);
    float z2 = lerp(e2.p1.p.z, e2.p2.p.z, u);

    return abs(z1 - z2);
  }
}