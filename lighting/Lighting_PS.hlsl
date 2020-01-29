// Skyrim Special Edition - BSLightingShader pixel shader  

// only NONE technique, no flags

// note: in the game's renderer PARALLAX, PARALLAXOCC, FACEGEN, and FACEGEN_RGB_TINT do not update the eye (view) position so this output will be wrong unless specular is also enabled
#if defined(SPECULAR) || defined(ENVMAP) || defined(PARALLAX) || defined(PARALLAX_OCC) || defined(FACEGEN) || defined(FACEGEN_RGB_TINT) || defined(MULTILAYERPARALLAX) || defined(EYE)
#define HAS_VIEW_DIRECTION_VECTOR_OUTPUT
#endif

#if defined(SKINNED) || defined(ENVMAP) || defined(EYE) || defined(MULTILAYERPARALLAX)
#define DRAW_IN_WORLDSPACE
#endif

// this transform is primarly used to take normals into common space
// since common space is model space by default, its not present if there are model space normals and the shader is not drawing in world space
#if defined(DRAW_IN_WORLDSPACE) || !defined(MODELSPACENORMALS)
#define HAS_COMMON_TRANSFORM
#endif

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

cbuffer PerFrame : register(b12)
{
    row_major float4x4 ViewMatrix							: packoffset(c0);
    row_major float4x4 ProjMatrix                           : packoffset(c4);
    row_major float4x4 ViewProjMatrix                       : packoffset(c8);
    row_major float4x4 ViewProjMatrixUnjittered             : packoffset(c12);
    row_major float4x4 PreviousViewProjMatrixUnjittered     : packoffset(c16);
    row_major float4x4 InvProjMatrixUnjittered              : packoffset(c20);
    row_major float4x4 ProjMatrixUnjittered                 : packoffset(c24);
    row_major float4x4 InvViewMatrix                        : packoffset(c28);
    row_major float4x4 InvViewProjMatrix                    : packoffset(c32);
    row_major float4x4 InvProjMatrix                        : packoffset(c36);
    float4   CurrentPosAdjust                               : packoffset(c40);
    float4   PreviousPosAdjust                              : packoffset(c41);
    float4   Unk42                                          : packoffset(c42);
    float4   Unk43                                          : packoffset(c43);
    float4   Unk44                                          : packoffset(c44);
}

SamplerState DiffuseSampler : register(s0);
Texture2D<float4> TexDiffuseSampler : register(t0);
SamplerState NormalSampler : register(s1);
Texture2D<float4> TexNormalSampler : register(t1);

struct PS_INPUT
{
    precise float4 ProjVertexPos            : SV_POSITION0;
#if defined(MULTI_TEXTURE) || defined(PROJECTED_UV)
    float4 TexCoords                        : TEXCOORD0;
#else
    float2 TexCoords                        : TEXCOORD0;
#endif
#if defined(DRAW_IN_WORLDSPACE)
    precise float3 WorldSpaceVertexPos      : TEXCOORD4;
#elif defined(WORLD_MAP)
    precise float3 WorldMapVertexPos        : TEXCOORD4;
#else
    precise float3 ModelSpaceVertexPos      : TEXCOORD4;
#endif
#if defined(HAS_COMMON_TRANSFORM)
#if defined(MODELSPACENORMALS)
    float3 ModelWorldTransform0             : TEXCOORD1;
    float3 ModelWorldTransform1             : TEXCOORD2;
    float3 ModelWorldTransform2             : TEXCOORD3;
#elif defined(DRAW_IN_WORLDSPACE)
    float3 TangentWorldTransform0           : TEXCOORD1;
    float3 TangentWorldTransform1           : TEXCOORD2;
    float3 TangentWorldTransform2           : TEXCOORD3;
#else
    float3 TangentModelTransform0           : TEXCOORD1;
    float3 TangentModelTransform1           : TEXCOORD2;
    float3 TangentModelTransform2           : TEXCOORD3;
#endif
#endif
#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    float3 ViewDirectionVec                 : TEXCOORD5;
#endif
#if defined(MULTI_TEXTURE)
    float4 BlendWeight0                     : TEXCOORD6;
    float4 BlendWeight1                     : TEXCOORD7;
#endif
#if defined(EYE)
    float3 EyeDirectionVec                  : TEXCOORD6;
#endif
#if defined(PROJECTED_UV)
    float3 ProjDir                          : TEXCOORD7;
#endif
#if defined(MODELSPACENORMALS)
    float3 ModelViewTransform0              : TEXCOORD8;
    float3 ModelViewTransform1              : TEXCOORD9;
    float3 ModelViewTransform2              : TEXCOORD10;
#else
    float3 TangentViewTransform0            : TEXCOORD8;
    float3 TangentViewTransform1            : TEXCOORD9;
    float3 TangentViewTransform2            : TEXCOORD10;
#endif
    precise float4 WorldVertexPos           : POSITION1;
    precise float4 PreviousWorldVertexPos   : POSITION2;
    float4 VertexColor                      : COLOR0;
    float4 FogParam                         : COLOR1;
};

struct PS_OUTPUT
{
    float4 Color                           : SV_Target0;
    float4 MotionVector                    : SV_Target1;
    float4 Normal                          : SV_Target2;
#if defined(SNOW)
    float4 SnowMask                        : SV_Target3;
#endif
};

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
    v_DiffuseAccumulator = DirLightColor.xyz *v_DirectionalLightIntensity;

    // point lights
    for (int currentLight = 0; currentLight < v_TotalLightCount; currentLight++)
    {
        float3 LightDirectionVec = PointLightPosition[currentLight].xyz - input.ModelSpaceVertexPos;
        float LightAttenuation = 1 - pow(saturate(length(LightDirectionVec) / PointLightPosition[currentLight].w), 2);
        float3 n_LightDirectionVec = normalize(LightDirectionVec);
        float LightIntensity = saturate(dot(v_CommonSpaceNormal.xyz, n_LightDirectionVec.xyz));
        v_DiffuseAccumulator += PointLightColor[currentLight].xyz * LightIntensity * LightAttenuation;
    }

    v_CommonSpaceNormal.w = 1;

    // directional ambient
    // don't understand this exactly 
    float3 DirectionalAmbientNormal = float3(
        dot(DirectionalAmbient[0].xyzw, v_CommonSpaceNormal.xyzw),
        dot(DirectionalAmbient[1].xyzw, v_CommonSpaceNormal.xyzw),
        dot(DirectionalAmbient[2].xyzw, v_CommonSpaceNormal.xyzw)
        );
    v_DiffuseAccumulator += EmitColor.xyz + DirectionalAmbientNormal.xyz;

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
    float v_FogAmount = input.FogParam.w;
    float3 v_FogDiffuse = lerp(v_OutDiffuse, input.FogParam.xyz, v_FogAmount);
    float3 v_FogAdjustedDiffuse = v_OutDiffuse - v_FogDiffuse * FogColor.w;

    // ColorOutputClamp.x = fLightingOutputColourClampPostLit
    // CLEANUP
    float3 v_Unk = v_FogAdjustedDiffuse * Unk42.y + ColourOutputClamp.x;
    float3 v_Unk2 = v_FogAdjustedDiffuse * Unk42.y;

    v_OutDiffuse = min(v_OutDiffuse, v_Unk);

    output.Color.w = input.VertexColor.w * MaterialData.z * v_Diffuse.w;
    output.Color.xyz = v_OutDiffuse - (v_Unk2 * Unk42.z);

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

    // CLEANUP
    // SSRParams.x = fSpecMaskBegin
    // SSRParams.y = fSpecMaskSpan + fSpecMaskBegin
    // SSRParams.w = 1.0 or fSpecularLODFade if RAW_FLAG_SPECULAR
    float v_SpecMask1 = SSRParams.x - 0.000010;
    float v_SpecMask2 = SSRParams.y - v_SpecMask1;
    v_SpecMask1 = v_Normal.w - v_SpecMask2;
    v_SpecMask2 = 1 / v_SpecMask2;
    v_SpecMask1 = saturate(v_SpecMask1 * v_SpecMask2);
    v_SpecMask2 = v_SpecMask1 * -2 + 3;
    v_SpecMask1 = pow(v_SpecMask1, 2);
    v_SpecMask1 = v_SpecMask1 * v_SpecMask2;

    // note that normal alpha = specular
    output.Normal.w = SSRParams.w * v_SpecMask1;

    v_ViewSpaceNormal.z = v_ViewSpaceNormal.z * -8 + 8;
    v_ViewSpaceNormal.z = sqrt(v_ViewSpaceNormal.z);
    v_ViewSpaceNormal.z = max(0.001, v_ViewSpaceNormal.z);

    output.Normal.xy = float2(0.5, 0.5) + (v_ViewSpaceNormal.xy / v_ViewSpaceNormal.z);
    output.MotionVector.zw = float2(0, 1);
    output.Normal.z = 0;

    return output;
}