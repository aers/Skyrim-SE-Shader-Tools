// Skyrim Special Edition - BSLightingShader pixel shader  

#include "Common.h"
#include "LightingCommon.h"

// Dynamic buffer: sizeof() = 32 (0x20)
cbuffer PerTechnique : register(b0)
{
    float4 FogColor                              : packoffset(c0);      // @ 0 - 0x0000
    float4 ColourOutputClamp                     : packoffset(c1);      // @ 4 - 0x0010
#if defined(DEFSHADOW)
    float4 VPOSOffset                            : packoffset(c2);      // @ 8 - 0x0020
#endif
}

// Dynamic buffer: sizeof() = 240 (0xF0)
cbuffer PerMaterial : register(b1)
{
    float4 LODTexParams                          : packoffset(c0);      // @ 0 - 0x0000
    float4 TintColor                             : packoffset(c1);      // @ 4 - 0x0010
    float4 EnvmapData                            : packoffset(c2);      // @ 8 - 0x0020
    float4 ParallaxOccData                       : packoffset(c3);      // @ 12 - 0x0030
    float4 SpecularColor                         : packoffset(c4);      // @ 16 - 0x0040
    float4 SparkleParams                         : packoffset(c5);      // @ 20 - 0x0050
    float4 MultiLayerParallaxData                : packoffset(c6);      // @ 24 - 0x0060
    float4 LightingEffectParams                  : packoffset(c7);      // @ 28 - 0x0070
    float4 IBLParams                             : packoffset(c8);      // @ 32 - 0x0080
    float4 LandscapeTexture1to4IsSnow            : packoffset(c9);      // @ 36 - 0x0090
    float4 LandscapeTexture5to6IsSnow            : packoffset(c10);     // @ 40 - 0x00A0
    float4 LandscapeTexture1to4IsSpecPower       : packoffset(c11);     // @ 44 - 0x00B0
    float4 LandscapeTexture5to6IsSpecPower       : packoffset(c12);     // @ 48 - 0x00C0
    float4 SnowRimLightParameters                : packoffset(c13);     // @ 52 - 0x00D0
    float4 CharacterLightParams                  : packoffset(c14);     // @ 56 - 0x00E0
}

// Dynamic buffer: sizeof() = 480 (0x1E0)
cbuffer PerGeometry : register(b2)
{
    float3 DirLightDirection                     : packoffset(c0);      // @ 0 - 0x0000
    float3 DirLightColor                         : packoffset(c1);      // @ 4 - 0x0010
    float4 ShadowLightMaskSelect                 : packoffset(c2);      // @ 8 - 0x0020
    float4 MaterialData                          : packoffset(c3);      // @ 12 - 0x0030
    float AlphaTestRef : packoffset(c4);      // @ 16 - 0x0040
    float3 EmitColor                             : packoffset(c4.y);    // @ 17 - 0x0044
    float4 ProjectedUVParams                     : packoffset(c6);      // @ 24 - 0x0060
    float4 SSRParams                             : packoffset(c7);      // @ 28 - 0x0070
    float4 WorldMapOverlayParametersPS           : packoffset(c8);      // @ 32 - 0x0080
    float4 ProjectedUVParams2                    : packoffset(c9);      // @ 36 - 0x0090
    float4 ProjectedUVParams3                    : packoffset(c10);     // @ 40 - 0x00A0
    row_major float3x4 DirectionalAmbient        : packoffset(c11);     // @ 44 - 0x00B0
    float4 AmbientSpecularTintAndFresnelPower    : packoffset(c14);     // @ 56 - 0x00E0
    float4 PointLightPosition[7]                 : packoffset(c15);     // @ 60 - 0x00F0
    float4 PointLightColor[7]                    : packoffset(c22);     // @ 88 - 0x0160
    float2 NumLightNumShadowLight                : packoffset(c29);     // @ 116 - 0x01D0
}

SamplerState DiffuseSampler : register(s0);
Texture2D<float4> TexDiffuseSampler : register(t0);
SamplerState NormalSampler : register(s1);
Texture2D<float4> TexNormalSampler : register(t1);

struct PS_OUTPUT
{
    float4 Color                           : SV_Target0;
    float4 MotionVector                    : SV_Target1;
    float4 Normal                          : SV_Target2;
#if defined(SNOW)
    float4 SnowMask                        : SV_Target3;
#endif
};

float3 DirectionalLightDiffuse(float3 a_lightPosition, float3 a_lightColor, float a_lightPower, float3 a_Position, float3 a_Normal)
{
    float3 v_lightDirection = a_LightPosition - a_Position;
    float v_lightAttenuation = 1 - pow(saturate(length(v_lightDirection) / a_lightPower), 2);
    float3 v_lightDirectionN = normalize(v_lightDirection);
    float v_lightIntensity = saturate(dot(a_Normal, v_lightDirectionN));
    return a_lightColor * v_lightIntensity * v_lightAttenuation;
}

PS_OUTPUT PSMain(PS_INPUT input)
{
    PS_OUTPUT output;

    float4 v_Diffuse = TexDiffuseSampler.Sample(DiffuseSampler, input.TexCoords.xy).xyzw;
    float4 v_Normal = TexNormalSampler.Sample(NormalSampler, input.TexCoords.xy).xyzw;

    v_Normal.xyz = v_Normal.xyz * 2 - 1;

    int v_TotalLightCount = min(7, NumLightNumShadowLight.x);

    float4 v_CommonSpaceNormal;
    
    v_CommonSpaceNormal.xyz = normalize(float3(
        dot(input.TangentModelTransform0.xyz, v_Normal.xyz),
        dot(input.TangentModelTransform1.xyz, v_Normal.xyz),
        dot(input.TangentModelTransform2.xyz, v_Normal.xyz)));

    float3 v_DiffuseAccumulator = 0;

    // directional light
    float v_DirectionalLightIntensity = saturate(dot(v_CommonSpaceNormal.xyz, DirLightDirection.xyz));
    v_DiffuseAccumulator = DirLightColor.xyz * v_DirectionalLightIntensity;

    // point lights
    for (int currentLight = 0; currentLight < v_TotalLightCount; currentLight++)
    {
        v_DiffuseAccumulator += DirectionalLightDiffuse(PointLightPosition[currentLight].xyz, PointLightColor[currentLight].xyz, PointLightPosition[currentLight].w, input.ModelSpaceVertexPos.xyz, v_CommonSpaceNormal.xyz);
    }

    v_CommonSpaceNormal.w = 1;

    // directional ambient
    // don't understand this exactly 
    float3 DirectionalAmbientNormal = float3(
        dot(DirectionalAmbient[0].xyzw, v_CommonSpaceNormal.xyzw),
        dot(DirectionalAmbient[1].xyzw, v_CommonSpaceNormal.xyzw),
        dot(DirectionalAmbient[2].xyzw, v_CommonSpaceNormal.xyzw)
        );
    v_DiffuseAccumulator += DirectionalAmbientNormal.xyz;

    v_DiffuseAccumulator += EmitColor.xyz;

    // IBL
    v_DiffuseAccumulator += IBLParams.yzw * IBLParams.x;

    float3 v_OutDiffuse = v_DiffuseAccumulator.xyz * v_Diffuse.xyz * input.VertexColor.xyz;

    // motion vector
    float2 v_CurrProjPosition = float2(
        dot(ViewProjMatrixUnjittered[0].xyzw, input.WorldVertexPos.xyzw),
        dot(ViewProjMatrixUnjittered[1].xyzw, input.WorldVertexPos.xyzw)) 
        / dot(ViewProjMatrixUnjittered[3].xyzw, input.WorldVertexPos.xyzw);
    float2 v_PrevProjPosition = float2(
        dot(PreviousViewProjMatrixUnjittered[0].xyzw, input.PreviousWorldVertexPos.xyzw),
        dot(PreviousViewProjMatrixUnjittered[1].xyzw, input.PreviousWorldVertexPos.xyzw))
        / dot(PreviousViewProjMatrixUnjittered[3].xyzw, input.PreviousWorldVertexPos.xyzw);
    float2 v_MotionVector = (v_CurrProjPosition - v_PrevProjPosition) * float2(-0.5, 0.5);

    // fog
    // SE implements fog as an imagespace shader after the main lighting pass so this is wasted on 95%~ of lighting shader runs
    float v_FogAmount = input.FogParam.w;
    float3 v_FogDiffuse = lerp(v_OutDiffuse, input.FogParam.xyz, v_FogAmount);
    float3 v_FogDiffuseDiff = v_OutDiffuse - v_FogDiffuse * FogColor.w;
 
    // FirstPerson seems to be 1 regardless of 1st/3rd person in SE, could be LE legacy code or a bug
    // AlphaPass is 0 before the fog imagespace shader runs and 1 after
    float FirstPerson = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.y;
    float AlphaPass = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.z;

    // ColorOutputClamp.x = fLightingOutputColourClampPostLit
    v_OutDiffuse = min(v_OutDiffuse, v_FogDiffuseDiff * FirstPerson + ColourOutputClamp.x);

    output.Color.w = input.VertexColor.w * MaterialData.z * v_Diffuse.w;
    output.Color.xyz = v_OutDiffuse - (v_FogDiffuseDiff * FirstPerson * AlphaPass);

    if (SSRParams.z > 0.000010)
    {
        output.MotionVector.xy = float2(1, 0);
    }
    else
    {
        output.MotionVector.xy = v_MotionVector.xy;
    }

    float3 v_ViewSpaceNormal = normalize(float3(
        dot(input.TangentViewTransform0.xyz, v_Normal.xyz),
        dot(input.TangentViewTransform1.xyz, v_Normal.xyz),
        dot(input.TangentViewTransform2.xyz, v_Normal.xyz)));

    // specular map for SSR
    // SSRParams.x = fSpecMaskBegin
    // SSRParams.y = fSpecMaskSpan + fSpecMaskBegin
    // SSRParams.w = 1.0 or fSpecularLODFade if RAW_FLAG_SPECULAR
    float v_SpecMaskBegin = SSRParams.x - 0.000010;
    float v_SpecMaskSpan = SSRParams.y;
    // specularity is in the normal alpha

    output.Normal.w = SSRParams.w * smoothstep(v_SpecMaskBegin, v_SpecMaskSpan, v_Normal.w);

    // view space normal map
    v_ViewSpaceNormal.z = v_ViewSpaceNormal.z * -8 + 8;
    v_ViewSpaceNormal.z = sqrt(v_ViewSpaceNormal.z);
    v_ViewSpaceNormal.z = max(0.001, v_ViewSpaceNormal.z);

    output.Normal.xy = float2(0.5, 0.5) + (v_ViewSpaceNormal.xy / v_ViewSpaceNormal.z);
    output.MotionVector.zw = float2(0, 1);
    output.Normal.z = 0;

    return output;
}