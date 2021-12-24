module aabb;

import ray;
import v3;

struct AABB
{
	V3 minimum;
	V3 maximum;

	bool hit(in Ray ray, double tMin, double tMax)
	{
		foreach (a; 0 .. 3)
		{
			auto invDir = 1.0 / ray.dir[a];
			auto t0 = (minimum[a] - ray.origin[a]) * invDir;
			auto t1 = (maximum[a] - ray.origin[a]) * invDir;
			if (invDir < 0.0)
			{
				auto tmp = t0;
				t0 = t1;
				t1 = tmp;
			}
			tMin = t0 > tMin ? t0 : tMin;
			tMax = t1 < tMin ? t1 : tMax;

			if (tMax <= tMin)
				return false;
		}
		return true;
	}

	AABB expand(in AABB rhs)
	{
		import std.algorithm : min, max;

		// dfmt off
		return 
		AABB(
			V3(
				min(minimum.x, rhs.minimum.x),
				min(minimum.y, rhs.minimum.y),
				min(minimum.z, rhs.minimum.z)
			),
			V3(
				max(maximum.x, rhs.maximum.x),
				max(maximum.y, rhs.maximum.y),
				max(maximum.z, rhs.maximum.z)
			)
		);
		// dfmt on
	}
}
