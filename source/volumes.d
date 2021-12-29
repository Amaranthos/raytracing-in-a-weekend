module volumes;

import aabb;
import colour;
import geometry;
import hit_record;
import material;
import ray;
import texture;
import v3;

class ConstantMedium : Geometry
{
	Geometry boundary;
	Material phaseFunc;
	double negInvDensity;

	this(Geometry geo, double density, Texture tex)
	{
		this.boundary = geo;
		this.negInvDensity = -1 / density;
		this.phaseFunc = new Isotropic(tex);
	}

	this(Geometry geo, double density, Colour colour)
	{
		this.boundary = geo;
		this.negInvDensity = -1 / density;
		this.phaseFunc = new Isotropic(colour);
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		import std.math : log;
		import std.random : uniform01;
		import std.stdio : writefln;

		const enableDebug = false;
		const debugging = enableDebug && uniform01 < 0.00001;

		HitRecord rec1, rec2;

		if (!boundary.hit(ray, -double.infinity, double.infinity, rec1))
			return false;
		if (!boundary.hit(ray, rec1.t + 0.0001, double.infinity, rec2))
			return false;

		if (debugging)
			writefln!"\ntMin: %s, tMax: %s"(rec1.t, rec2.t);

		if (rec1.t < tMin)
			rec1.t = tMin;
		if (rec2.t > tMax)
			rec2.t = tMax;

		if (rec1.t >= rec2.t)
			return false;

		if (rec1.t < 0)
			rec1.t = 0;

		const rayLength = ray.dir.magnitude;
		const distanceInsideBoundary = (rec2.t - rec1.t) * rayLength;
		const hitDistance = negInvDensity * log(uniform01);

		if (hitDistance > distanceInsideBoundary)
			return false;

		rec.t = rec1.t + hitDistance / rayLength;
		rec.pos = ray.at(rec.t);

		rec.norm = V3.right;
		rec.frontFace = true;
		rec.mat = phaseFunc;

		if (debugging)
			writefln!"hitDistance: %s, rec: %s"(hitDistance, rec);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		return boundary.boundingBox(t0, t1, boundingBox);
	}
}
