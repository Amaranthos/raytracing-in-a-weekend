module hit_record;

import std.typecons;

import material;
import ray;
import v3;

struct HitRecord
{
	V3 pos;
	V3 norm;
	Material mat;
	double t;
	double u;
	double v;
	bool frontFace;

	void setFaceNormal(in Ray ray, in V3 outwardNorm)
	{
		frontFace = ray.dir.dot(outwardNorm) < 0;
		norm = frontFace ? outwardNorm : -outwardNorm;
	}
}
