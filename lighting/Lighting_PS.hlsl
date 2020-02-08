// Skyrim Special Edition - BSLightingShader pixel shader  

// support technique: NONE, ENVMAP, GLOWMAP, PARALLAX
// support flags: VC, SKINNED, MODELSPACENORMALS, SPECULAR, SOFT_LIGHTING, RIM_LIGHTING, BACK_LIGHTING, SHADOW_DIR, DEFSHADOW, PROJECTED_UV, DEPTH_WRITE_DECALS, ANISO_LIGHTING, AMBIENT_SPECULAR, BASE_OBJECT_IS_SNOW, DO_ALPHA_TEST, SNOW, CHARACTER_LIGHT

#include "Common.h"
#include "LightingCommon.h"

#if defined(ADDITIONAL_ALPHA_MASK)
const static float AAM[] = { 0.003922, 0.533333, 0.133333, 0.666667, 0.800000, 0.266667, 0.933333, 0.400000, 0.200000, 0.733333, 0.066667, 0.600000, 0.996078, 0.466667, 0.866667, 0.333333 };
#endif

// Dynamic buffer: sizeof() = 32 (0x20)
cbuffer PerTechnique : register(b0)
{
    float4 FogColor                              : packoffset(c0);      // @ 0 - 0x0000
    float4 ColourOutputClamp                     : packoffset(c1);      // @ 4 - 0x0010
#if defined(DEFSHADOW) || defined(SHADOW_DIR)
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
#if defined(MODELSPACENORMALS)
SamplerState SpecularSampler : register(s2);
Texture2D<float4> TexSpecularSampler : register(t2);
#endif
// NOTE: Parallax + ProjUV incompatible due to this
#if defined(PARALLAX)
SamplerState HeightSampler : register(s3);
Texture2D<float4> TexHeightSampler : register(t3);
#endif
#if defined(PROJECTED_UV)
SamplerState ProjectedDiffuseSampler : register(s3);
Texture2D<float4> TexProjectedDiffuseSampler : register(t3);
#endif
#if defined(ENVMAP)
SamplerState EnvSampler : register(s4);
Texture2D<float4> TexEnvSampler : register(t4);
SamplerState EnvMaskSampler : register(s5);
Texture2D<float4> TexEnvMaskSampler : register(t5);
#endif
#if defined(GLOWMAP)
SamplerState GlowSampler : register(s6);
Texture2D<float4> TexGlowSampler : register(t6);
#endif
#if defined(PROJECTED_UV)
SamplerState ProjectedNormalSampler : register(s8);
Texture2D<float4> TexProjectedNormalSampler : register(t8);
#endif
#if defined(BACK_LIGHTING)
SamplerState BackLightMaskSampler : register(s9);
Texture2D<float4> TexBackLightMaskSampler : register(t9);
#endif
#if defined(PROJECTED_UV)
SamplerState ProjectedNormalDetailSampler : register(s10);
Texture2D<float4> TexProjectedNormalDetailSampler : register(t10);
#endif
#if defined(PROJECTED_UV) || defined(CHARACTER_LIGHT)
SamplerState ProjectedNoiseSampler : register(s11);
Texture2D<float4> TexProjectedNoiseSampler : register(t11);
#endif
#if defined(SOFT_LIGHTING) || defined(RIM_LIGHTING)
SamplerState SubSurfaceSampler : register(s12);
Texture2D<float4> TexSubSurfaceSampler : register(t12);
#endif
#if defined(WORLD_MAP)
SamplerState WorldMapOverlayNormalSampler : register(s12);
Texture2D<float4> TexWorldMapOverlayNormalSampler : register(t12);
SamplerState WorldMapOverlayNormalSnowSampler : register(s13);
Texture2D<float4> TexWorldMapOverlayNormalSnowSampler : register(t13);
#endif
#if defined(DEFSHADOW) || defined(SHADOW_DIR)
SamplerState ShadowMaskSampler : register(s14);
Texture2D<float4> TexShadowMaskSampler : register(t14);
#endif

struct PS_OUTPUT
{
    float4 Color                           : SV_Target0;
    float4 MotionVector                    : SV_Target1;
    float4 Normal                          : SV_Target2;
#if defined(SNOW)
    float4 SnowMask                        : SV_Target3;
#endif
};

float3 DirectionalLightDiffuse(float3 a_lightDirectionN, float3 a_lightColor, float3 a_Normal)
{
    float v_lightIntensity = saturate(dot(a_Normal, a_lightDirectionN));
    return a_lightColor * v_lightIntensity;
}

float3 DirectionalLightSpecular(float3 a_lightDirectionN, float3 a_lightColor, float a_specularPower, float3 a_viewDirectionN, float3 a_Normal)
{
    float3 v_halfAngle = normalize(a_lightDirectionN + a_viewDirectionN);
    float v_specIntensity = saturate(dot(v_halfAngle, a_Normal));
    float v_spec = pow(v_specIntensity, a_specularPower);

    return a_lightColor * v_spec;
}

float3 AnisotropicSpecular(float3 a_lightDirectionN, float3 a_lightColor, float a_specularPower, float3 a_viewDirectionN, float3 a_Normal, float3 a_VertexNormal)
{
    float3 v_halfAngle = normalize(a_lightDirectionN + a_viewDirectionN);
    float3 v_anisoDir = normalize(a_Normal * 0.5 + a_VertexNormal);

    float v_anisoIntensity = 1 - min(1, abs(dot(v_anisoDir, a_lightDirectionN) - dot(v_anisoDir, v_halfAngle)));
    float v_spec = 0.7 * pow(v_anisoIntensity, a_specularPower);

    return a_lightColor * v_spec * max(0, a_lightDirectionN.z);
}

float3 SoftLighting(float3 a_lightDirection, float3 a_lightColor, float3 a_softMask, float a_softRolloff, float3 a_Normal)
{
    float v_softIntensity = dot(a_Normal, a_lightDirection);

    float v_soft_1 = smoothstep(-a_softRolloff, 1.0, v_softIntensity);
    float v_soft_2 = smoothstep(0, 1.0, v_softIntensity);

    float v_soft = saturate(v_soft_1 - v_soft_2);

    return a_lightColor * a_softMask * v_soft;
}

float3 RimLighting(float3 a_lightDirectionN, float3 a_lightColor, float3 a_softMask, float a_rimPower, float3 a_viewDirectionN, float3 a_Normal)
{
    float NdotV = saturate(dot(a_Normal, a_viewDirectionN));
    
    float v_rim_1 = pow(1 - NdotV, a_rimPower);
    float v_rim_2 = saturate(dot(a_viewDirectionN, -a_lightDirectionN));

    float v_rim = v_rim_1 * v_rim_2;

    return a_lightColor * a_softMask * v_rim;
}

float3 BackLighting(float3 a_lightDirectionN, float3 a_lightColor, float3 a_backMask, float3 a_Normal)
{
    float v_backIntensity = dot(a_Normal, -a_lightDirectionN);

    return a_lightColor * a_backMask * v_backIntensity;
}

float3 toGrayscale(float3 a_Color)
{
    return dot(float3(0.3, 0.59, 0.11), a_Color);
}

PS_OUTPUT PSMain(PS_INPUT input)
{
    PS_OUTPUT output;

#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    float3 v_ViewDirectionVec = normalize(input.ViewDirectionVec);
#else
    // sometimes used for calculations when there's no actual view direction vec
    float3 v_ViewDirectionVec = normalize(float3(1, 1, 1));
#endif

#if defined(PARALLAX)
#if defined(DRAW_IN_WORLDSPACE)
    float3x3 v_CommonTangentMatrix = transpose(float3x3(input.TangentWorldTransform0.xyz, input.TangentWorldTransform1.xyz, input.TangentWorldTransform2.xyz));
#else
    float3x3 v_CommonTangentMatrix = transpose(float3x3(input.TangentModelTransform0.xyz, input.TangentModelTransform1.xyz, input.TangentModelTransform2.xyz));
#endif
    float3 v_TangentViewDirection = normalize(float3(
        dot(v_CommonTangentMatrix[0].xyz, input.ViewDirectionVec.xyz),
        dot(v_CommonTangentMatrix[1].xyz, input.ViewDirectionVec.xyz),
        dot(v_CommonTangentMatrix[2].xyz, input.ViewDirectionVec.xyz));

    float height = TexHeightSampler.Sample(HeightSampler, v_TexCoords.xy).x * 0.0800 - 0.0400;
#if defined(FIX_VANILLA_BUGS)
    float2 v_TexCoords = v_TangentViewDirection.xy * height + v_TexCoords.xy;
#else
    float2 v_TexCoords = v_ViewDirectionVec.xy * height + v_TexCoords.xy;
#endif
#else
    float2 v_TexCoords = v_TexCoords.xy;
#endif

    float4 v_Diffuse = TexDiffuseSampler.Sample(DiffuseSampler, v_TexCoords.xy).xyzw;

#if defined(MODELSPACENORMALS)
    float3 v_Normal = TexNormalSampler.Sample(NormalSampler, v_TexCoords.xy).xzy;
#else
    float4 v_Normal = TexNormalSampler.Sample(NormalSampler, v_TexCoords.xy).xyzw;
#endif

    v_Normal.xyz = v_Normal.xyz * 2 - 1;

#if defined(MODELSPACENORMALS)
    float v_SpecularPower = TexSpecularSampler.Sample(SpecularSampler, v_TexCoords.xy).x;
#else
    float v_SpecularPower = v_Normal.w;
#endif

#if defined(SOFT_LIGHTING) || defined(RIM_LIGHTING)
    float3 v_SubSurfaceTexMask = TexSubSurfaceSampler.Sample(SubSurfaceSampler, v_TexCoords.xy).xyz;
#endif

#if defined(BACK_LIGHTING)
    float3 v_BackLightingTexMask = TexBackLightMaskSampler.Sample(BackLightMaskSampler, v_TexCoords.xy).xyz;
#endif

#if defined(SOFT_LIGHTING)
    float v_SoftRolloff = LightingEffectParams.x; // fSubSurfaceLightRolloff
#endif

#if defined(RIM_LIGHTING)
    float v_RimPower = LightingEffectParams.y; // fRimLightPower
#endif

    int v_TotalLightCount = min(7, NumLightNumShadowLight.x);
#if defined(DEFSHADOW) || defined(SHADOW_DIR)
    int v_ShadowLightCount = min(4, NumLightNumShadowLight.y);
#endif

#if (defined(ANISO_LIGHTING) || defined(WORLD_MAP) || defined(SNOW)) && !defined(MODELSPACENORMALS)
#if defined(DRAW_IN_WORLDSPACE)
    float3 v_VertexNormal = float3(input.TangentWorldTransform0.z, input.TangentWorldTransform1.z, input.TangentWorldTransform2.z);
    float3 v_VertexNormalN = normalize(v_VertexNormal);
#else
    float3 v_VertexNormal = float3(input.TangentModelTransform0.z, input.TangentModelTransform1.z, input.TangentModelTransform2.z);
    float3 v_VertexNormalN = normalize(v_VertexNormal);
#endif
#endif

#if defined(WORLD_MAP) 
    // need to implement LODLand/LODObj/LODObjHD to be sure of this, so not bothering yet
#endif

    float4 v_CommonSpaceNormal;
    
#if defined(MODELSPACENORMALS)
#if defined(DRAW_IN_WORLDSPACE) 
    v_CommonSpaceNormal.xyz = normalize(float3(
        dot(input.ModelWorldTransform0.xyz, v_Normal.xyz),
        dot(input.ModelWorldTransform1.xyz, v_Normal.xyz),
        dot(input.ModelWorldTransform2.xyz, v_Normal.xyz)
        ));
#else
    v_CommonSpaceNormal.xyz = v_Normal.xyz;
#endif
#elif defined(DRAW_IN_WORLDSPACE)
    v_CommonSpaceNormal.xyz = normalize(float3(
        dot(input.TangentWorldTransform0.xyz, v_Normal.xyz),
        dot(input.TangentWorldTransform1.xyz, v_Normal.xyz),
        dot(input.TangentWorldTransform2.xyz, v_Normal.xyz)
        ));
#else
    v_CommonSpaceNormal.xyz = normalize(float3(
        dot(input.TangentModelTransform0.xyz, v_Normal.xyz),
        dot(input.TangentModelTransform1.xyz, v_Normal.xyz),
        dot(input.TangentModelTransform2.xyz, v_Normal.xyz)
        ));
#endif

    float3 v_CommonSpaceVertexPos;

#if defined(DRAW_IN_WORLDSPACE)
    v_CommonSpaceVertexPos = input.WorldSpaceVertexPos;
#else
    v_CommonSpaceVertexPos = input.ModelSpaceVertexPos;
#endif


// note: MULTIINDEXTRISHAPE technique has different code here
#if defined(PROJECTED_UV)
    float2 v_ProjectedUVCoords = input.TexCoords.zw * ProjectedUVParams.z;
    float v_ProjUVNoise = TexProjectedNoiseSampler.Sample(ProjectedNoiseSampler, v_ProjectedUVCoords.xy).x;
    float3 v_ProjDirN = normalize(input.ProjDir.xyz);
    float v_NdotP = dot(v_CommonSpaceNormal.xyz, v_ProjDirN.xyz);
    float v_ProjDiffuseIntensity = v_NdotP * input.VertexColor.w - ProjectedUVParams.w - (ProjectedUVParams.x * v_ProjUVNoise);
#if defined(SNOW)
    float v_ProjUVDoSnowRim = 0;
#endif
    // ProjectedUVParams3.w = EnableProjectedNormals
    if (ProjectedUVParams3.w > 0.5)
    {
        // fProjectedUVDiffuseNormalTilingScale
        float2 v_ProjectedUVDiffuseNormalCoords = v_ProjectedUVCoords * ProjectedUVParams3.x;
        // fProjectedUVNormalDetailTilingScale
        float2 v_ProjectedUVNormalDetailCoords = v_ProjectedUVCoords * ProjectedUVParams3.y;

        float3 v_ProjectedNormal = TexProjectedNormalSampler.Sample(ProjectedNormalSampler, v_ProjectedUVDiffuseNormalCoords.xy).xyz;
        v_ProjectedNormal = v_ProjectedNormal * 2 - 1;
        float3 v_ProjectedNormalDetail = TexProjectedNormalDetailSampler.Sample(ProjectedNormalDetailSampler, v_ProjectedUVNormalDetailCoords.xy).xyz;

        float3 v_ProjectedNormalCombined = v_ProjectedNormalDetail * 2 + float3(v_ProjectedNormal.x, v_ProjectedNormal.y, -1);
        v_ProjectedNormalCombined.xy = v_ProjectedNormalCombined.xy + float2(-1, -1);
        v_ProjectedNormalCombined.z = v_ProjectedNormalCombined.z * v_ProjectedNormal.z;

        float3 v_ProjectedNormalCombinedN = normalize(v_ProjectedNormalCombined);

        float3 v_ProjectedDiffuse = TexProjectedDiffuseSampler.Sample(ProjectedDiffuseSampler, v_ProjectedUVDiffuseNormalCoords.xy).xyz;

        float v_AdjProjDiffuseIntensity = smoothstep(-0.100000, 0.100000, v_ProjDiffuseIntensity);

        // note that this modifies the original normal, not the common space one that is used for lighting calculation
        // it ends up only being used later on for the view space normal used for the normal map output which is used for later image space shaders
        // unsure if this is a bug
        v_Normal.xyz = lerp(v_Normal.xyz, v_ProjectedNormalCombinedN.xyz, v_AdjProjDiffuseIntensity);
        v_Diffuse.xyz = lerp(v_Diffuse.xyz, v_ProjectedDiffuse.xyz * ProjectedUVParams2.xyz, v_AdjProjDiffuseIntensity);
#if defined(SNOW)
        v_ProjUVDoSnowRim = -1;
#if defined(BASE_OBJECT_IS_SNOW)
        output.SnowMask.y = min(1, v_AdjProjDiffuseIntensity + v_Diffuse.w);
#else
        output.SnowMask.y = v_AdjProjDiffuseIntensity;
#endif
#endif
    }
    else
    {
        if (v_ProjDiffuseIntensity > 0)
        {
            v_Diffuse.xyz = ProjectedUVParams2.xyz;
#if defined(SNOW)
            v_ProjUVDoSnowRim = -1;
#if defined(BASE_OBJECT_IS_SNOW)
            output.SnowMask.y = min(1, v_ProjDiffuseIntensity + v_Diffuse.w);
#else
            output.SnowMask.y = v_ProjDiffuseIntensity;
#endif
#endif
        }
#if defined(SNOW)
        else
        {
            output.SnowMask.y = 0;
        }
#endif
    }
#endif

#if defined(DEFSHADOW) || defined(SHADOW_DIR)
    float4 v_ShadowMask;
#if !defined(SHADOW_DIR)
    if (v_ShadowLightCount > 0)
    {
#endif
        float2 DRes_Inv = float2(DynamicRes_InvWidthX_InvHeightY_WidthClampZ_HeightClampW.xy);
        float2 DRes = float2(DynamicRes_WidthX_HeightY_PreviousWidthZ_PreviousHeightW.xy);
        float DRes_WidthClamp = DynamicRes_InvWidthX_InvHeightY_WidthClampZ_HeightClampW.z;

        float2 v_ShadowMaskPos = (DRes_Inv.xy * input.ProjVertexPos.xy * VPOSOffset.xy + VPOSOffset.zw) * DRes.xy;
        // Uses the Height instead of HeightClamp for clamping; HeightClamp is unusued anywhere else in the shader
        // Presumably this is intentional but who knows 
        v_ShadowMaskPos = clamp(float2(0, 0), float2(DRes_WidthClamp, DRes.y), v_ShadowMaskPos);

        v_ShadowMask = TexShadowMaskSampler.Sample(ShadowMaskSampler, v_ShadowMaskPos).xyzw;
#if !defined(SHADOW_DIR)
    }
    else
    {
        v_ShadowMask = float4(1, 1, 1, 1);
    }
#endif
#endif

    float3 v_DiffuseAccumulator = 0;

#if defined(SPECULAR)
    float3 v_SpecularAccumulator = 0;
#endif

#if defined(SHADOW_DIR)
    float v_DirLightShadowedFactor = v_ShadowMask.x;
    float3 v_DirLightColor = DirLightColor.xyz * v_DirLightShadowedFactor;
#else
    float3 v_DirLightColor = DirLightColor.xyz;
#endif
    // directional light
    v_DiffuseAccumulator = DirectionalLightDiffuse(DirLightDirection.xyz, v_DirLightColor, v_CommonSpaceNormal.xyz);

#if defined(SOFT_LIGHTING)
    v_DiffuseAccumulator += SoftLighting(DirLightDirection.xyz, v_DirLightColor, v_SubSurfaceTexMask, v_SoftRolloff, v_CommonSpaceNormal.xyz);
#endif

#if defined(RIM_LIGHTING)
    v_DiffuseAccumulator += RimLighting(DirLightDirection.xyz, v_DirLightColor, v_SubSurfaceTexMask, v_RimPower, v_ViewDirectionVec, v_CommonSpaceNormal.xyz);
#endif

#if defined(BACK_LIGHTING)
    v_DiffuseAccumulator += BackLighting(DirLightDirection.xyz, v_DirLightColor, v_BackLightingTexMask, v_CommonSpaceNormal.xyz);
#endif

    // TODO - refactor defines
#if defined(SNOW)
    // snow rim lighting
    float v_SnowRimLight = 0.0;
#if defined(PROJECTED_UV)
    if (v_ProjUVDoSnowRim != 0)
    {
#endif
        // bEnableSnowRimLighting
        if (SnowRimLightParameters.w > 0.0)
        {
            float v_SnowRimLightIntensity = SnowRimLightParameters.x;
            float v_SnowGeometrySpecPower = SnowRimLightParameters.y;
            float v_SnowNormalSpecPower = SnowRimLightParameters.z;

            float v_SnowRim_Normal = pow(1 - saturate(dot(v_CommonSpaceNormal.xyz, v_ViewDirectionVec.xyz)), v_SnowNormalSpecPower);
#if defined(MODELSPACENORMALS)
            float v_SnowRim_Geometry = pow(1 - saturate(v_ViewDirectionVec.z), v_SnowGeometrySpecPower);
#else
            float v_SnowRim_Geometry = pow(1 - saturate(dot(v_VertexNormalN.xyz, v_ViewDirectionVec.xyz)), v_SnowGeometrySpecPower);
#endif
            v_SnowRimLight = v_SnowRim_Normal * v_SnowRim_Geometry * v_SnowRimLightIntensity;

#if defined(SPECULAR)
            v_SpecularAccumulator.xyz = v_SnowRimLight.xxx;
#endif
        }
#if defined(PROJECTED_UV)
    }
#endif
#endif
#if defined(SPECULAR) && (!defined(SNOW) || defined(PROJECTED_UV))
#if defined(PROJECTED_UV) && defined(SNOW)
    else
    {
#endif
#if defined(ANISO_LIGHTING)
        v_SpecularAccumulator = AnisotropicSpecular(DirLightDirection.xyz, v_DirLightColor, SpecularColor.w, v_ViewDirectionVec, v_CommonSpaceNormal.xyz, v_VertexNormal);
#else
        v_SpecularAccumulator = DirectionalLightSpecular(DirLightDirection.xyz, v_DirLightColor, SpecularColor.w, v_ViewDirectionVec, v_CommonSpaceNormal.xyz);
#endif
#if defined(PROJECTED_UV) && defined(SNOW)
    }
#endif
#endif

    // point lights
    for (int currentLight = 0; currentLight < v_TotalLightCount; currentLight++)
    {
#if defined(DEFSHADOW) || defined(SHADOW_DIR)
        float v_ShadowedFactor;

        if (currentLight < v_ShadowLightCount)
        {
            int v_ShadowMaskOffset = (int) dot(ShadowLightMaskSelect.xyzw, M_IdentityMatrix[currentLight].xyzw);
            v_ShadowedFactor = dot(v_ShadowMask.xyzw, M_IdentityMatrix[v_ShadowMaskOffset].xyzw);
        }
        else
        {
            v_ShadowedFactor = 1;
        }

        float3 v_lightColor = PointLightColor[currentLight].xyz * v_ShadowedFactor;
#else
        float3 v_lightColor = PointLightColor[currentLight].xyz;
#endif
        
        float3 v_lightDirection = PointLightPosition[currentLight].xyz - v_CommonSpaceVertexPos.xyz;
        float v_lightRadius = PointLightPosition[currentLight].w;
        float v_lightAttenuation = 1 - pow(saturate(length(v_lightDirection) / v_lightRadius), 2);
        float3 v_lightDirectionN = normalize(v_lightDirection);
        float3 v_SingleLightDiffuseAccumulator = DirectionalLightDiffuse(v_lightDirectionN, v_lightColor, v_CommonSpaceNormal.xyz);
#if defined(SOFT_LIGHTING)
        // NOTE: This is using the un-normalized light direction. Unsure if this is a bug or intentional.
        v_SingleLightDiffuseAccumulator += SoftLighting(v_lightDirection, v_lightColor, v_SubSurfaceTexMask, v_SoftRolloff, v_CommonSpaceNormal.xyz);
#endif
#if defined(RIM_LIGHTING)
        v_SingleLightDiffuseAccumulator += RimLighting(v_lightDirectionN, v_lightColor, v_SubSurfaceTexMask, v_RimPower, v_ViewDirectionVec, v_CommonSpaceNormal.xyz);
#endif
#if defined(BACK_LIGHTING)
        v_SingleLightDiffuseAccumulator += BackLighting(v_lightDirectionN, v_lightColor, v_BackLightingTexMask, v_CommonSpaceNormal.xyz);
#endif
        v_DiffuseAccumulator += v_lightAttenuation * v_SingleLightDiffuseAccumulator;
#if defined(SPECULAR)
#if defined(ANISO_LIGHTING)
        v_SpecularAccumulator += v_lightAttenuation * AnisotropicSpecular(v_lightDirectionN, v_lightColor, SpecularColor.w, v_ViewDirectionVec, v_CommonSpaceNormal.xyz, v_VertexNormal);
#else
        v_SpecularAccumulator += v_lightAttenuation * DirectionalLightSpecular(v_lightDirectionN, v_lightColor, SpecularColor.w, v_ViewDirectionVec, v_CommonSpaceNormal.xyz);
#endif
#endif
    }

#if defined(ENVMAP)
    float v_EnvMapMask = TexEnvMaskSampler.Sample(EnvMaskSampler, v_TexCoords.xy).x;

    float v_EnvMapScale = EnvmapData.x;
    float v_EnvMapLODFade = MaterialData.x;
    float v_HasEnvMapMask = EnvmapData.y;
    
    // if/else implemented as lerp with 0.0/1.0 param
    float v_EnvMapIntensity = lerp(v_SpecularPower, v_EnvMapMask, v_HasEnvMapMask) * v_EnvMapScale * v_EnvMapLODFade;
    float3 v_ReflectionVec = 2 * dot(v_CommonSpaceNormal.xyz, v_ViewDirectionVec.xyz) * v_CommonSpaceNormal.xyz - v_ViewDirectionVec.xyz;

    float3 v_EnvMapColor = TexEnvSampler.Sample(EnvSampler, v_ReflectionVec.xyz).xyz * v_EnvMapIntensity;
#endif

    // toggled by cl on/off
    // brightens the output
#if defined(CHARACTER_LIGHT)
    float CharacterLightingStrengthPrimary = CharacterLightParams.x;
    float CharacterLightingStrengthSecondary = CharacterLightParams.y;
    float CharacterLightingStrengthLuminance = CharacterLightParams.z;
    float CharacterLightingStrengthMaxLuminance = CharacterLightParams.w;

    float VdotN = saturate(dot(v_ViewDirectionVec, v_CommonSpaceNormal.xyz));
    // TODO: these constants are probably something simple
    float SecondaryIntensity = saturate(dot(float2(0.164399, -0.986394), v_CommonSpaceNormal.yz));

    float CharacterLightingStrength = VdotN * CharacterLightingStrengthPrimary + SecondaryIntensity * CharacterLightingStrengthSecondary;
    float Noise = TexProjectedNoiseSampler.Sample(ProjectedNoiseSampler, float2(1, 1)).x;
    float CharacterLightingLuminance = clamp(CharacterLightingStrengthLuminance * Noise, 0, CharacterLightingStrengthMaxLuminance);
    v_DiffuseAccumulator += CharacterLightingStrength * CharacterLightingLuminance;
#endif

    v_CommonSpaceNormal.w = 1;

    // directional ambient
    // don't understand this exactly 
    float3 DirectionalAmbientNormal = float3(
        dot(DirectionalAmbient[0].xyzw, v_CommonSpaceNormal.xyzw),
        dot(DirectionalAmbient[1].xyzw, v_CommonSpaceNormal.xyzw),
        dot(DirectionalAmbient[2].xyzw, v_CommonSpaceNormal.xyzw)
        );
    v_DiffuseAccumulator += DirectionalAmbientNormal.xyz;

#if defined(GLOWMAP)
    float3 v_GlowColor = TexGlowSampler.Sample(GlowSampler, v_TexCoords.xy).xyz;
    v_DiffuseAccumulator += EmitColor.xyz * v_GlowColor.xyz;
#else
    v_DiffuseAccumulator += EmitColor.xyz;
#endif

    // IBL
    v_DiffuseAccumulator += IBLParams.yzw * IBLParams.x;

    float3 v_OutDiffuse = v_DiffuseAccumulator.xyz * v_Diffuse.xyz * input.VertexColor.xyz;

#if defined(ENVMAP)
    v_OutDiffuse += v_DiffuseAccumulator.xyz * v_EnvMapColor.xyz;
#endif

#if defined(SPECULAR) 
    float3 v_OutSpecular;
#if defined(PROJECTED_UV) && defined(SNOW)
    if (v_ProjUVDoSnowRim != 0)
    {
        v_OutSpecular = float3(0, 0, 0);
    }
    else
    {
        v_OutSpecular = v_SpecularAccumulator.xyz * v_SpecularPower * MaterialData.y;
    }
#elif !defined(SNOW)
    v_OutSpecular = v_SpecularAccumulator.xyz * v_SpecularPower * MaterialData.y;
#endif
#endif

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

#if defined(AMBIENT_SPECULAR)
    float v_AmbientSpecularIntensity = pow(1 - saturate(dot(v_CommonSpaceNormal.xyz, v_ViewDirectionVec)), AmbientSpecularTintAndFresnelPower.w);
    float4 v_CommonSpaceNormal_AS = float4(v_CommonSpaceNormal.xyz, 0.15);
    float3 v_AmbientSpecularColor = AmbientSpecularTintAndFresnelPower.xyz *
        float3(
            saturate(dot(DirectionalAmbient[0].xyzw, v_CommonSpaceNormal_AS.xyzw)),
            saturate(dot(DirectionalAmbient[1].xyzw, v_CommonSpaceNormal_AS.xyzw)),
            saturate(dot(DirectionalAmbient[2].xyzw, v_CommonSpaceNormal_AS.xyzw))
            );

    float3 v_AmbientSpecular = v_AmbientSpecularColor * v_AmbientSpecularIntensity;
#endif

    // FirstPerson seems to be 1 regardless of 1st/3rd person in SE, could be LE legacy code or a bug
    // AlphaPass is 0 before the fog imagespace shader runs and 1 after
    float FirstPerson = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.y;
    float AlphaPass = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.z;

    // fog
    // SE implements fog as an imagespace shader after the main lighting pass so this is wasted on 95%~ of lighting shader runs
    // this code is probably actually completely different then this, its just what it compiled to, needs refactor probably
    float v_FogAmount = input.FogParam.w;
    float3 v_FogDiffuse = lerp(v_OutDiffuse, input.FogParam.xyz, v_FogAmount);
    float3 v_FogDiffuseDiff = v_OutDiffuse - v_FogDiffuse * FogColor.w;

    // ColorOutputClamp.x = fLightingOutputColourClampPostLit
    v_OutDiffuse = min(v_OutDiffuse, v_FogDiffuseDiff * FirstPerson + ColourOutputClamp.x);

#if defined(SPECULAR) || defined(AMBIENT_SPECULAR)
#if defined(SPECULAR) && (!defined(SNOW) || defined(PROJECTED_UV))
    v_OutDiffuse += v_OutSpecular * SpecularColor.xyz;
#endif
#if defined(AMBIENT_SPECULAR)
    v_OutDiffuse += v_AmbientSpecular;
#endif
    v_FogDiffuse = lerp(v_OutDiffuse, input.FogParam.xyz, v_FogAmount);
    v_FogDiffuseDiff = v_OutDiffuse - v_FogDiffuse * FogColor.w;

    // ColourOutputClamp.z = fLightingOutputColourClampPostSpec
    v_OutDiffuse = min(v_OutDiffuse, v_FogDiffuseDiff * FirstPerson + ColourOutputClamp.z);
#endif

#if defined(ADDITIONAL_ALPHA_MASK)
    uint2 v_ProjVertexPosTrunc = (uint2) input.ProjVertexPos.xy;

    // 0xC - 0b1100
    // 0x3 - 0b0011
    uint v_AAM_Index = (v_ProjVertexPosTrunc.x << 2) & 0xC | (v_ProjVertexPosTrunc.y) & 0x3;

    float v_AAM = MaterialData.z - AAM[v_AAM_Index];
    
    if (v_AAM < 0)
    {
        discard;
    }

    float v_OutAlpha = input.VertexColor.w * v_Diffuse.w;
#else
    // MaterialData.z = LightingProperty Alpha
    float v_OutAlpha = input.VertexColor.w * MaterialData.z * v_Diffuse.w;
#endif

#if defined(DEPTH_WRITE_DECALS)
    if (v_OutAlpha - 0.0156863 < 0)
    {
        discard;
    }
    v_OutAlpha = saturate(1.05 * v_OutAlpha);
#endif

#if defined(DO_ALPHA_TEST)
    if (v_OutAlpha - AlphaTestRefCB.x < 0)
    {
        discard;
    }
#endif

    output.Color.w = v_OutAlpha;
    output.Color.xyz = v_OutDiffuse - (v_FogDiffuseDiff * FirstPerson * AlphaPass);

    if (SSRParams.z > 0.000010)
    {
        output.MotionVector.xy = float2(1, 0);
    }
    else
    {
        output.MotionVector.xy = v_MotionVector.xy;
    }

#if defined(MODELSPACENORMALS)
    float3 v_ViewSpaceNormal = normalize(float3(
        dot(input.ModelViewTransform0.xyz, v_Normal.xyz),
        dot(input.ModelViewTransform1.xyz, v_Normal.xyz),
        dot(input.ModelViewTransform2.xyz, v_Normal.xyz)));
#else
    float3 v_ViewSpaceNormal = normalize(float3(
        dot(input.TangentViewTransform0.xyz, v_Normal.xyz),
        dot(input.TangentViewTransform1.xyz, v_Normal.xyz),
        dot(input.TangentViewTransform2.xyz, v_Normal.xyz)));
#endif

    // specular map for SSR
    // SSRParams.x = fSpecMaskBegin
    // SSRParams.y = fSpecMaskSpan + fSpecMaskBegin
    // SSRParams.w = 1.0 or fSpecularLODFade if RAW_FLAG_SPECULAR
    float v_SpecMaskBegin = SSRParams.x - 0.000010;
    float v_SpecMaskSpan = SSRParams.y;
    // specularity is in the normal alpha

    output.Normal.w = SSRParams.w * smoothstep(v_SpecMaskBegin, v_SpecMaskSpan, v_SpecularPower);

    // view space normal map
    v_ViewSpaceNormal.z = v_ViewSpaceNormal.z * -8 + 8;
    v_ViewSpaceNormal.z = sqrt(v_ViewSpaceNormal.z);
    v_ViewSpaceNormal.z = max(0.001, v_ViewSpaceNormal.z);

    output.Normal.xy = float2(0.5, 0.5) + (v_ViewSpaceNormal.xy / v_ViewSpaceNormal.z);
    output.MotionVector.zw = float2(0, 1);
    output.Normal.z = 0;

#if defined(SNOW)
#if defined(SPECULAR)
    output.SnowMask.x = toGrayscale(v_SpecularAccumulator);
#else
    output.SnowMask.x = toGrayscale(v_SnowRimLight);
#endif
#if !defined(PROJECTED_UV)
    output.SnowMask.y = v_Diffuse.w;
#endif
#endif

    return output;
}