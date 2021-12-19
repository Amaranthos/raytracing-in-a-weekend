module bitmap_header;

struct BitmapHeader
{
align(1):
	ushort fileType;
	uint fileSize;
	ushort reserved1;
	ushort reserved2;
	uint bitmapOffset;
	uint size;
	int width;
	int height;
	ushort planes;
	ushort bitsPerPixel;
	uint compression;
	uint sizeOfBitmap;
	int horzResolution;
	int vertResolution;
	uint colorsUsed;
	uint colorsImportant;
	uint redMask;
	uint greenMask;
	uint blueMask;
}
