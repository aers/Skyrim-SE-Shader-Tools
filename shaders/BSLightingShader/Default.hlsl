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
    PS_OUTPUT output;
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
    
    float3 outDiffuse = data.diffuseLighting * data.diffuseColour * input.VertexColour.xyz;
    
    // diffuse clamping
    float gs_fLightingOutputColourClampPostLit = ColourOutputClamp.x;
    
    outDiffuse = min(outDiffuse, gs_fLightingOutputColourClampPostLit);
   
    float3 outColour = outDiffuse;    
        
    // add specular contribution
#if defined(SPECULAR)
    float cb_LightingProperty_fSpecularLODFade = MaterialData.y;
    float3 outSpecular = data.specularLighting * data.specularPower * cb_LightingProperty_fSpecularLODFade * SpecularColour.xyz;
    
    outColour += outSpecular;
    
    float gs_fLightingOutputColourClampPostSpec = ColourOutputClamp.z;
    outColour = min(outColour, gs_fLightingOutputColourClampPostSpec);
#endif    
    
    // fog
    float cb_FirstPerson = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.y;
    float cb_AlphaPass = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.z;
    float shouldFogOutput = cb_FirstPerson * cb_AlphaPass;  
    float cb_fInvFrameBufferRange = FogColour.w;
    
    float3 fogColour = input.FogParam.xyz;
    float fogAmount = input.FogParam.w;   
    
    float3 foggedColour = lerp(outColour, fogColour, fogAmount) * cb_fInvFrameBufferRange;
    
    output.Colour.xyz = lerp(outColour, foggedColour, shouldFogOutput);
    
    // alpha
    float cb_LightingProperty_fAlpha = MaterialData.z;
    
    float outAlpha = input.VertexColour.w * cb_LightingProperty_fAlpha * data.diffuseAlpha;
    
    output.Colour.w = outAlpha;
    
    // motion vector
    float2 currProjPosition = float2(dot(ViewProjMatrixUnjittered[0].xyzw, input.WorldVertexPos.xyzw), dot(ViewProjMatrixUnjittered[1].xyzw, input.WorldVertexPos.xyzw)) / dot(ViewProjMatrixUnjittered[3].xyzw, input.WorldVertexPos.xyzw);
    float2 prevProjPosition = float2(dot(PreviousViewProjMatrixUnjittered[0].xyzw, input.PreviousWorldVertexPos.xyzw), dot(PreviousViewProjMatrixUnjittered[1].xyzw, input.PreviousWorldVertexPos.xyzw)) / dot(PreviousViewProjMatrixUnjittered[3].xyzw, input.PreviousWorldVertexPos.xyzw);
    float2 motionVector = (currProjPosition - prevProjPosition) * float2(-0.5, 0.5);
    
    if (SSRParams.z > 0.000010)
    {
        output.MotionVector.xy = float2(1, 0);
    }
    else
    {
        output.MotionVector.xy = motionVector.xy;
    }    
    output.MotionVector.zw = float2(0, 1);    
    
    // output normal 
    float3x3 viewSpaceTransform = float3x3(input.ViewSpaceTransform0, input.ViewSpaceTransform1, input.ViewSpaceTransform2);
    
    float3 viewSpaceNormal = normalize(mul(viewSpaceTransform, data.normal.xyz));
    viewSpaceNormal.z = max(0.001, sqrt(viewSpaceNormal.z * -8 + 8));
    
    output.Normal.xy = float2(0.5, 0.5) + (viewSpaceNormal.xy / viewSpaceNormal.z);
    output.Normal.z = 0;
    
    // output normal alpha stores a specular mask for use by other shaders
    float cb_SpecMaskBegin = SSRParams.x;
    float cb_SpecMaskEnd = SSRParams.y;
    float gs_fSpecularLODFade = SSRParams.w;    

    output.Normal.w = gs_fSpecularLODFade * smoothstep(cb_SpecMaskBegin - 0.000010, cb_SpecMaskEnd, data.specularPower);
    
    return output;
}

#endif