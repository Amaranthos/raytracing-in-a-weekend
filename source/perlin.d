module perlin;

import v3;

import std.random : uniform01, uniform;

static this()
{
	foreach (ref v; ranVec)
	{
		v = V3.random(-1, 1);
	}

	permX = generatePerm;
	permY = generatePerm;
	permZ = generatePerm;
}

public double turb(V3 point, int depth = 7)
{
	auto accum = 0.0;
	auto tmpP = point;
	auto weight = 1.0;

	foreach (i; 0 .. depth)
	{
		accum += weight * noise(tmpP);
		weight *= 0.5;
		tmpP *= 2;
	}

	import std.math : abs;

	return abs(accum);
}

public double noise(in V3 point)
{
	import std.math : floor;

	auto u = point.x - floor(point.x);
	auto v = point.y - floor(point.y);
	auto w = point.z - floor(point.z);

	auto i = cast(int) floor(point.x);
	auto j = cast(int) floor(point.y);
	auto k = cast(int) floor(point.z);

	V3[2][2][2] c;
	foreach (int di; 0 .. 2)
	{
		foreach (int dj; 0 .. 2)
		{
			foreach (int dk; 0 .. 2)
			{
				// dfmt off
				c[dk][dj][di] = ranVec[
					permX[(i + di) & (pointCount - 1)] ^
					permX[(j + dj) & (pointCount - 1)] ^
					permX[(k + dk) & (pointCount - 1)]
				];
				// dfmt on
			}
		}
	}

	return perlinInterpolation(c, u, v, w);
}

private:

enum int pointCount = 256;
V3[pointCount] ranVec;
int[pointCount] permX;
int[pointCount] permY;
int[pointCount] permZ;

int[pointCount] generatePerm()
{
	int[pointCount] p;
	foreach (idx, ref i; p)
	{
		i = cast(int) idx;
	}

	permute(p, pointCount);
	return p;
}

void permute(ref int[pointCount] p, int n)
{
	foreach_reverse (int i; 1 .. n)
	{
		int target = uniform(0, i);
		int tmp = p[i];
		p[i] = p[target];
		p[target] = tmp;
	}
}

double perlinInterpolation(V3[2][2][2] c, double u, double v, double w)
{
	auto uu = u ^^ 2 * (3 - 2 * u);
	auto vv = v ^^ 2 * (3 - 2 * v);
	auto ww = w ^^ 2 * (3 - 2 * w);
	auto accum = 0.0;

	foreach (int i; 0 .. 2)
	{
		foreach (int j; 0 .. 2)
		{
			foreach (int k; 0 .. 2)
			{
				V3 weight = V3(u - i, v - j, w - k);
				accum +=
					(i * uu + (1 - i) * (1 - uu)) *
					(j * vv + (1 - j) * (1 - vv)) *
					(k * ww + (1 - k) * (1 - ww)) *
					weight.dot(c[k][j][i]);
			}
		}
	}
	return accum;
}
