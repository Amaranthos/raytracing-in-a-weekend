module ray;

import v3;

struct Ray
{
	V3 origin;
	V3 dir;

	V3 at(double t) const
	{
		return origin + t * dir;
	}
}
