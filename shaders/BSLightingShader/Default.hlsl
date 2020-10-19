// BSLightingShader - Default Technique (ID 0)

// Supported Flags
// 1<<0 Vc      #define VC                      enforced on all pixel shader passes by renderer code
// 1<<1 Sk      #define SKINNED                        
// 1<<2 Msn     #define MODELSPACENORMALS
// 1<<9 Spc     #define SPECULAR
// 1<<10 Sss    #define SOFT_LIGHTING
// 1<<11 Rim    #define RIM_LIGHTING
// 1<<12 Bk     #define BACK_LIGHTING
// 1<<13 Sh     #define SHADOW_DIR
// 1<<14 DfSh   #define DEFSHADOW
// 1<<15 Projuv #define PROJECTED_UV
// 1<<16 (None) #define ANISO_LIGHTING

#include "include/CommonDefines.hlsli"
#include "include/ConstantBuffers.hlsli"
#include "include/InputOutput.hlsli"

#if defined(PIXELSHADER)

#include "include/Samplers.hlsli"
#include "include/CommonPS.hlsl"
#include "include/Lighting.hlsl"
#if defined(PROJECTED_UV)
#include "include/ProjectedUV.hlsl"
#endif

PS_OUTPUT PSMain(PS_INPUT input)
{
    psInternalData data = (psInternalData) 0;
    
    data.input = input;
    
    GetViewDirection(data);
    
    // diffuse from texture   
    GetDiffuse(data);
    
    // normal from texture, calculated normals, and specular power
    GetNormalsAndSpecularPower(data);
    
    // subsurface mask texture used for soft and rim lighting
#if defined(SOFT_LIGHTING) || defined(RIM_LIGHTING)
    GetSubsurfaceMask(data);
#endif    
    
    // back lighting mask texture
#if defined(BACK_LIGHTING)
    GetBacklightMask(data);
#endif
    
#if defined(PROJECTED_UV)
    ApplyProjectedUV(data);
#endif
    
#if defined(SPECULAR)
    GetSpecularHardness(data);
#endif
    
    // light counts and shadow mask
    GetLightData(data);
    
    // directional light
    AddDirectionalLight(data);
    
    // point lights
    AddPointLights(data);
    
    // directional ambient
    AddDirectionalAmbient(data);
    
    // emit colour
    AddEmit(data);
    
    // fake IBL
    AddIBL(data);
    
    GetOutDiffuse(data);
        
    // add specular contribution
#if defined(SPECULAR)
    AddOutSpecular(data);
#endif    
    
    // fog
    ApplyFog(data);
    
    data.output.Colour.xyz = data.outColour;
    
    // alpha
    float cb_LightingProperty_fAlpha = MaterialData.z;
    
    float outAlpha = input.VertexColour.w * cb_LightingProperty_fAlpha * data.diffuseAlpha;
    
    data.output.Colour.w = outAlpha;
    
    // motion vector
    SetOutputMotionVector(data);
    
    // output normal 
    SetOutputNormal(data);
    
    // output normal alpha stores a specular mask for use by other shaders
    SetOutputSpecMask(data);
    
    return data.output;
}

#endif