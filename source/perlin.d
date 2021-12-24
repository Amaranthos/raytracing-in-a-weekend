module perlin;

import v3;

import std.random : uniform01, uniform;

static this()
{
	ranFloat = new double[pointCount];
	foreach (ref i; ranFloat)
	{
		i = uniform01;
	}
	permX = generatePerm;
	permY = generatePerm;
	permZ = generatePerm;
}

public double noise(in V3 point)
{
	auto i = cast(int)(4 * point.x) & (pointCount - 1);
	auto j = cast(int)(4 * point.y) & (pointCount - 1);
	auto k = cast(int)(4 * point.z) & (pointCount - 1);

	return ranFloat[permX[i] ^ permY[j] ^ permZ[k]];
}

private:

enum int pointCount = 256;
double[] ranFloat;
int[] permX;
int[] permY;
int[] permZ;

static int[] generatePerm()
{
	auto p = new int[pointCount];
	foreach (idx, ref i; p)
	{
		i = cast(int) idx;
	}

	permute(p, pointCount);
	return p;
}

static void permute(ref int[] p, int n)
{
	foreach_reverse (int i; 1 .. n)
	{
		int target = uniform(0, i);
		int tmp = p[i];
		p[i] = p[target];
		p[target] = tmp;
	}
}
