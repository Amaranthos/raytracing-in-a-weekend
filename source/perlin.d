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
	import std.math : floor;

	auto u = point.x - floor(point.x);
	auto v = point.y - floor(point.y);
	auto w = point.z - floor(point.z);

	auto i = cast(int) floor(point.x);
	auto j = cast(int) floor(point.y);
	auto k = cast(int) floor(point.z);

	double[2][2][2] c;
	foreach (int di; 0 .. 2)
	{
		foreach (int dj; 0 .. 2)
		{
			foreach (int dk; 0 .. 2)
			{
				// dfmt off
				c[dk][dj][di] = ranFloat[
					permX[(i + di) & (pointCount - 1)] ^
					permX[(j + dj) & (pointCount - 1)] ^
					permX[(k + dk) & (pointCount - 1)]
				];
				// dfmt on
			}
		}
	}

	return trilerp(c, u, v, w);
}

private:

enum int pointCount = 256;
double[] ranFloat;
int[] permX;
int[] permY;
int[] permZ;

int[] generatePerm()
{
	auto p = new int[pointCount];
	foreach (idx, ref i; p)
	{
		i = cast(int) idx;
	}

	permute(p, pointCount);
	return p;
}

void permute(ref int[] p, int n)
{
	foreach_reverse (int i; 1 .. n)
	{
		int target = uniform(0, i);
		int tmp = p[i];
		p[i] = p[target];
		p[target] = tmp;
	}
}

double trilerp(double[2][2][2] c, double u, double v, double w)
{
	auto sum = 0.0;
	foreach (int i; 0 .. 2)
	{
		foreach (int j; 0 .. 2)
		{
			foreach (int k; 0 .. 2)
			{
				sum +=
					(i * u + (1 - i) * (1 - u)) *
					(j * v + (1 - j) * (1 - v)) *
					(k * w + (1 - k) * (1 - w)) *
					c[k][j][i];
			}
		}
	}
	return sum;
}
