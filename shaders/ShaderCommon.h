// Shader Common

#ifndef WINPC
#error shader is only for Windows
#endif

#ifndef DX11
#error shader is only for DirectX 11
#endif

#if !defined(PIXELSHADER) && !defined(VERTEXSHADER) && !defined(HULLSHADER) && !defined(DOMAINSHADER) && !defined(COMPUTESHADER)
#error no valid shader type defined
#endif

// https://msdn.microsoft.com/en-us/library/4hwaceh6.aspx "math.h Math Constants"
#define M_PI  3.14159265358979323846 // PI
#define M_2PI 6.28318530717958647692 // PI * 2

const static float4x4 M_IdentityMatrix =
{
	{ 1, 0, 0, 0 },
	{ 0, 1, 0, 0 },
	{ 0, 0, 1, 0 },
	{ 0, 0, 0, 1 }
};