module bvh;

import aabb;
import geometry;
import hit_record;
import ray;
import v3;

import std.stdio : writeln;

class BVH : Geometry
{
	Geometry left;
	Geometry right;
	AABB box;

	this(Geometry[] geometries, double t0, double t1)
	{
		import std.random : uniform;

		int axis = uniform(0, 2);

		if (geometries.length == 1)
		{
			left = right = geometries[0];
		}
		else if (geometries.length == 2)
		{
			if (boxCompare(geometries[0], geometries[1], axis))
			{
				left = geometries[0];
				right = geometries[1];
			}
			else
			{
				left = geometries[1];
				right = geometries[0];
			}
		}
		else
		{
			import std.algorithm : sort;

			geometries.sort!((a, b) => boxCompare(a, b, axis));

			left = new BVH(geometries[0 .. $ / 2], t0, t1);
			right = new BVH(geometries[$ / 2 .. $], t0, t1);
		}

		AABB boxLeft;
		AABB boxRight;

		if (!left.boundingBox(t0, t1, boxLeft) || !right.boundingBox(t0, t1, boxRight))
			writeln("No bounding box found");

		box = boxLeft.expand(boxRight);
	}

	override bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		if (!box.hit(ray, tMin, tMax))
			return false;

		HitRecord recLeft;
		HitRecord recRight;

		bool hitLeft = left.hit(ray, tMin, tMax, recLeft);
		bool hitRight = right.hit(ray, tMin, hitLeft ? rec.t : tMax, recRight);

		if (hitLeft)
			rec = recLeft;
		if (hitRight)
			rec = recRight;

		return hitLeft || hitRight;
	}

	override bool boundingBox(double t0, double t1, out AABB boundingBox)
	{
		boundingBox = box;
		return true;
	}
}

private bool boxCompare(Geometry a, Geometry b, int axis)
in (axis >= 0 && axis < 3)
{
	AABB boxA;
	AABB boxB;

	if (!a.boundingBox(0, 0, boxA) || !b.boundingBox(0, 0, boxB))
		writeln("No bounding box found");

	return boxA.minimum[axis] < boxB.minimum[axis];
}
