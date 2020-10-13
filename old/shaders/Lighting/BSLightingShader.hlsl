#include "../ShaderCommon.h"
#include "include/Defines.h"
#include "include/InputOutput.h"
#include "include/ConstantBuffers.h"

#if defined(VERTEXSHADER)
#include "BSLightingShader.vs.hlsl"
#endif

#if defined(PIXELSHADER)
#include "BSLightingShader.ps.hlsl"
#endif

#if defined(HULLSHADER)
// placeholder
#endif

#if defined(DOMAINSHADER)
// placeholder
#endif