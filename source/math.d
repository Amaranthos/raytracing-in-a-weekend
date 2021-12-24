module math;

import std.math;

public:

double deg2Rad(double deg)
{
	return deg * PI / 180;
}

T lerp(T)(T a, T b, double t)
{
	return (1.0 - t) * a + t * b;
}
