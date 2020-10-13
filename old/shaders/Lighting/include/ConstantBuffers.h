// VS
#if defined(VERTEXSHADER)
cbuffer PerTechnique : register(b0)
{
    float4 HighDetailRange                       : packoffset(c0);      // @ 0 - 0x0000
    float4 FogParam                              : packoffset(c1);      // @ 4 - 0x0010
    float4 FogNearColor                          : packoffset(c2);      // @ 8 - 0x0020
    float4 FogFarColor                           : packoffset(c3);      // @ 12 - 0x0030
}

cbuffer PerMaterial : register(b1)
{
    float3 LeftEyeCenter                         : packoffset(c0);      // @ 0 - 0x0000
    float3 RightEyeCenter                        : packoffset(c1);      // @ 4 - 0x0010
    float4 TexCoordOffset                        : packoffset(c2);      // @ 8 - 0x0020
}

cbuffer PerGeometry : register(b2)
{
    row_major float3x4 World                     : packoffset(c0);      // @ 0 - 0x0000
    row_major float3x4 PreviousWorld             : packoffset(c3);      // @ 12 - 0x0030
    float3 EyePosition                           : packoffset(c6);      // @ 24 - 0x0060
    float4 LandBlendParams                       : packoffset(c7);      // @ 28 - 0x0070
    float4 TreeParams                            : packoffset(c8);      // @ 32 - 0x0080
    float2 WindTimers                            : packoffset(c9);      // @ 36 - 0x0090
    row_major float3x4 TextureProj               : packoffset(c10);     // @ 40 - 0x00A0
    float IndexScale                             : packoffset(c13);     // @ 52 - 0x00D0
    float4 WorldMapOverlayParameters             : packoffset(c14);     // @ 56 - 0x00E0
}

#if defined(SKINNED)
// these are 3x4 world transform matrices for up to 80 bones
// cb9 - prev bones
cbuffer PreviousBones : register(b9)
{
    float4 PreviousBones[240];
}
// cb10 - bones
cbuffer Bones : register(b10)
{
    float4 Bones[240];
}
#endif
#endif

// PS
#if defined(PIXELSHADER)
cbuffer PerTechnique : register(b0)
{
    float4 FogColor                              : packoffset(c0);      // @ 0 - 0x0000
    float4 ColourOutputClamp                     : packoffset(c1);      // @ 4 - 0x0010
#if defined(DEFSHADOW) || defined(SHADOW_DIR)
    float4 VPOSOffset                            : packoffset(c2);      // @ 8 - 0x0020
#endif
}

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

cbuffer PerGeometry : register(b2)
{
    float3 DirLightDirection                     : packoffset(c0);      // @ 0 - 0x0000
    float3 DirLightColor                         : packoffset(c1);      // @ 4 - 0x0010
    float4 ShadowLightMaskSelect                 : packoffset(c2);      // @ 8 - 0x0020
    float4 MaterialData                          : packoffset(c3);      // @ 12 - 0x0030
    float AlphaTestRef                           : packoffset(c4);      // @ 16 - 0x0040
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

#if defined(DO_ALPHA_TEST)
cbuffer AlphaTestRefCB : register(b11)
{
    float4 AlphaTestRefCB : packoffset(c0);
}
#endif
#endif

// Shared PerFrame buffer
cbuffer PerFrame : register(b12)
{
    row_major float4x4  ViewMatrix                                                  : packoffset(c0);
    row_major float4x4  ProjMatrix                                                  : packoffset(c4);
    row_major float4x4  ViewProjMatrix                                              : packoffset(c8);
    row_major float4x4  ViewProjMatrixUnjittered                                    : packoffset(c12);
    row_major float4x4  PreviousViewProjMatrixUnjittered                            : packoffset(c16);
    row_major float4x4  InvProjMatrixUnjittered                                     : packoffset(c20);
    row_major float4x4  ProjMatrixUnjittered                                        : packoffset(c24);
    row_major float4x4  InvViewMatrix                                               : packoffset(c28);
    row_major float4x4  InvViewProjMatrix                                           : packoffset(c32);
    row_major float4x4  InvProjMatrix                                               : packoffset(c36);
    float4              CurrentPosAdjust                                            : packoffset(c40);
    float4              PreviousPosAdjust                                           : packoffset(c41);
    // notes: FirstPersonY seems 1.0 regardless of third/first person, could be LE legacy stuff
    float4              GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW              : packoffset(c42);
    float4              DynamicRes_WidthX_HeightY_PreviousWidthZ_PreviousHeightW    : packoffset(c43);
    float4              DynamicRes_InvWidthX_InvHeightY_WidthClampZ_HeightClampW    : packoffset(c44);
}