import bindbc.sdl;
import bindbc.opengl;

import std.stdio;
import std.string;

import exception;
import colour;
import ray;
import v3;

enum double aspectRatio = 16.0 / 9.0;

enum uint texWidth = 500;
enum uint texHeight = cast(uint)(texWidth / aspectRatio);

enum uint winWidth = texWidth;
enum uint winHeight = texHeight;

enum double viewHeight = 2.0;
enum double viewWidth = aspectRatio * viewHeight;
enum double focalLength = 1.0;

enum V3 origin = V3.zero;
enum V3 hori = V3(viewWidth, 0.0, 0.0);
enum V3 vert = V3(0.0, viewHeight, 0.0);
enum V3 blCorner = origin - hori / 2.0 - vert / 2.0 - V3(0.0, 0.0, focalLength);

GLuint textureId;
uint[] texture;

Colour rayColour(in Ray ray)
{
	auto t = hitSphere(V3(0.0, 0.0, -1.0), 0.5, ray);
	if (t > 0.0)
	{
		V3 norm = (ray.at(t) - V3(0, 0, -1)).normalised;
		return cast(Colour)(0.5 * (norm + Colour.one));
	}

	V3 dir = ray.dir.normalised;
	t = 0.5 * (dir.y + 1.0);
	return cast(Colour) Colour.one.lerp(Colour(0.5, 0.7, 1.0), t);
}

double hitSphere(in V3 center, in double radius, in Ray ray)
{
	V3 oc = ray.origin - center;
	auto a = ray.dir.magnitudeSquared;
	auto halfB = oc.dot(ray.dir);
	auto c = oc.magnitudeSquared - radius ^^ 2;
	auto discriminant = halfB ^^ 2 - a * c;
	if (discriminant < 0)
	{
		return -1.0;
	}
	else
	{
		import std.math : sqrt;

		return (-halfB - discriminant.sqrt) / a;
	}
}

void loadScene()
{
	texture = new uint[](texWidth * texHeight);

	for (int j = texHeight - 1; j >= 0; --j)
	{
		writefln!"lines remaining: %s "(j);
		foreach (i; 0 .. texWidth)
		{
			const double u = cast(double)(i) / (texWidth - 1);
			const double v = cast(double)(j) / (texHeight - 1);

			Ray r = Ray(origin, blCorner + u * hori + v * vert - origin);
			V3 c = rayColour(r);

			// dfmt off
			texture[j * texWidth + i] =
				(cast(int)(  1 * 255)) << 24 |
				(cast(int)(c.z * 255)) << 16 |
				(cast(int)(c.y * 255)) <<  8 |
				(cast(int)(c.x * 255)) <<  0;
			// dfmt on
		}
	}

	writeln("done...");

	glGenTextures(1, &textureId);
	glBindTexture(GL_TEXTURE_2D, textureId);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

	glBindTexture(GL_TEXTURE_2D, 0);

	glFlush();
}

void unloadScene()
{
}

void renderScene()
{
	glClear(GL_COLOR_BUFFER_BIT);

	glBindTexture(GL_TEXTURE_2D, textureId);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture
			.ptr);
	glBindTexture(GL_TEXTURE_2D, 0);

	GLuint fboId;
	glGenFramebuffers(1, &fboId);
	glBindFramebuffer(GL_READ_FRAMEBUFFER, fboId);
	glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
		GL_TEXTURE_2D, textureId, 0);
	glBlitFramebuffer(0, 0, texWidth, texHeight,
		0, 0, winWidth, winHeight,
		GL_COLOR_BUFFER_BIT, GL_NEAREST);
	glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
	glDeleteFramebuffers(1, &fboId);
}

int main()
{
	SDLSupport sdlStatus = loadSDL();
	if (sdlStatus != sdlSupport)
	{
		writeln("Failed loading SDL: ", sdlStatus);
		return 1;
	}

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		throw new SDLException();

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	auto window = SDL_CreateWindow("OpenGL 3.2 App", SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED, winWidth, winHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
	if (!window)
		throw new SDLException();

	const context = SDL_GL_CreateContext(window);
	if (!context)
		throw new SDLException();

	if (SDL_GL_SetSwapInterval(1) < 0)
		writeln("Failed to set VSync");

	GLSupport glStatus = loadOpenGL();
	if (glStatus < glSupport)
	{
		writeln("Failed loading minimum required OpenGL version: ", glStatus);
		return 1;
	}

	loadScene();
	scope (exit)
		unloadScene();

	bool quit = false;
	SDL_Event event;
	while (!quit)
	{
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym)
				{
				case SDLK_ESCAPE:
					quit = true;
					break;

				default:
					break;
				}
				break;

			case SDL_QUIT:
				quit = true;
				break;

			default:
				break;
			}
		}

		renderScene();

		SDL_GL_SwapWindow(window);
	}

	return 0;
}
