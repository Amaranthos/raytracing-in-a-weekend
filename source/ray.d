module ray;

import v3;

struct Ray
{
	V3 origin;
	V3 dir;
	double time = 0.0;

	V3 at(double t) const
	{
		return origin + t * dir;
	}
}
