// Skyrim Special Edition - BSLightingShader vertex shader 

// techniques 
// 0 None
// 1 Envmap - #define ENVMAP
// 2 Glowmap - #define GLOWMAP
// 3 Parallax - #define PARALLAX
// 4 Facegen - #define FACEGEN
// 5 FacegenRGBTint - #define FACEGEN_RGB_TINT
// 6 Hair - #define HAIR
// 7 ParallaxOcc - #define PARALLAX_OCC
// 8 MTLand - #define MULTI_TEXTURE, #define LANDSCAPE
// 9 LODLand - #define LODLANDSCAPE
// 10 Unknown - Unused (SNOW)
// 11 MultiLayerParallax - #define MULTI_LAYER_PARALLAX, #define ENVMAP
// 12 Tree - #define TREE_ANIM
// 13 LODObj - #define LODOBJECTS
// 14 MultiIndexTriShapeSnow - #define MULTI_INDEX SPARKLE, #define SPARKLE
// 15 LODObjHD - #define LODOBJECTSHD
// 16 Eye - #define EYE
// 17 Unknown - Unused (#define CLOUD, #define INSTANCED)
// 18 LODLandNoise - #define LODLANDSCAPE, #define LODLANDNOISE
// 19 MTLandLODBlend - #define MULTI_TEXTURE, #define LANDSCAPE LOD_LAND_BLEND

// flags
// most flags are unused in VS, reference https://github.com/Nukem9/SkyrimSETest/blob/master/skyrim64_test/src/patches/TES/BSShader/Shaders/BSLightingShader.cpp#L1077
// 1<<0 Vc - #define VC
// 1<<1 Sk - #define SKINNED
// 1<<2 Msn - #define MODELSPACENORMALS
// 1<<9 Spc - #define SPECULAR
// 1<<15 Projuv - #define PROJECTED_UV
// 1<<15 DwDecals - #define DEPTH_WRITE_DECALS (HAIR technique only)
// 1<<18 Wmap - #define WORLD_MAP

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
    float IndexScale : packoffset(c13);     // @ 52 - 0x00D0
    float4 WorldMapOverlayParameters             : packoffset(c14);     // @ 56 - 0x00E0
}

#if defined(SKINNED)
// these are world transform matrices for up to 80 bones
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

// from FO4 EffectMAX.fx
float4 GetFog(float3 apPosition, float afNearInverseFarMinusNear, float afInverseFarMinusNear, float afPower, float afClamp, float3 NearColor, float3 FarColor)
{
    float4 ret;
    float dist = length(apPosition);
    ret.a = min(pow(saturate(dist * afInverseFarMinusNear - afNearInverseFarMinusNear), afPower), afClamp);
    ret.rgb = lerp(NearColor, FarColor, ret.a);

    return ret;
}

// tree branch animation in wind
// credit to arha for writing this out for me
float GetTreeDisplacement(float3 apVertexPosition, float4 aTreeParams, float afWindTimer, float afVertexAlpha)
{
    float windBase = aTreeParams.w * aTreeParams.y * afWindTimer.x; // constantly increasing values scaled by per-object tuning
    float2 windBands = windBase * float2(0.1, 0.25); // two bands of animation
    float cheapVertDistance = dot(apVertexPosition.xyz, float3(1, 1, 1)); // make objects with different object-space positions animate differently
    float2 windScales = frac(windBands + cheapVertDistance + float2(0.5, 0.5)); // combine together to get two [0, 1) bands
    float2 rescaledWind = (windScales * 2) - 1; // rescale to [-1, 1)
    float2 sawWave = 3 - abs(rescaledWind) * 2; // saw wave
    float2 curvedSaw = abs(rescaledWind) * abs(rescaledWind); // shape the wave
    float2 combinedSaw = sawWave * curvedSaw; // combine both waves together
    float displacementScale = (combinedSaw.x + combinedSaw.y * 0.1) * aTreeParams.z * afVertexAlpha;

    return displacementScale;
}

struct VS_INPUT
{
    precise float4 VertexPos            : POSITION0;
    float2 TexCoords                    : TEXCOORD0;
#if !defined(MODELSPACENORMALS)
    float4 Normal                       : NORMAL0;
    float4 Binormal                     : BINORMAL0;
#endif
#if defined(VC)
    float4 VertexColor                  : COLOR0;
#endif
#if defined(MULTI_TEXTURE)
    float4 BlendWeight0                 : TEXCOORD2;
    float4 BlendWeight1                 : TEXCOORD3;
#endif
#if defined(SKINNED)
    float4 BoneWeights                  : BLENDWEIGHT0;
    float4 BoneIndices                  : BLENDINDICES0;
#endif
#if defined(EYE)
    float IsRightEye : TEXCOORD2;
#endif
};

// the common transforms and vertex positions don't actually have different names, I chose to do it like this for my sanity
struct VS_OUTPUT
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

VS_OUTPUT VSMain(VS_INPUT input)
{
    VS_OUTPUT vsout;

    // represents the 4x4 world transformation matrix
    float4x4 v_World4x4;
    // represents the common space vertex position
    precise float4 v_VertexPos;
    precise float4 v_ModelVertexPos;
    float4 v_VertexColor;

    // vertex color is set to (1,1,1,1) if there isn't any; all pixel shaders use the vertex shader flag
#if defined(VC)
    v_VertexColor = input.VertexColor;
#else
    v_VertexColor = float4(1, 1, 1, 1);
#endif

#if defined(HAS_COMMON_TRANSFORM) && !defined(MODELSPACENORMALS)
    // bitangent is in the VertexPos, Normal, Binormal w
    // normal+tangent are stored as a single byte 0-255 and must be transformed to [-1, 1]
    float3 bitangent = float3(input.VertexPos.w, input.Normal.w * 2 - 1, input.Binormal.w * 2 - 1);
    float3 tangent = input.Binormal.xyz * 2 - 1;
    float3 normal = input.Normal.xyz * 2 - 1;
#endif

#if defined(TREE_ANIM)
    v_VertexPos = float4(input.VertexPos.xyz + normal * GetTreeDisplacement(input.VertexPos.xyz, TreeParams, WindTimers.x, v_VertexColor.w), 1);
#else
    v_VertexPos = float4(input.VertexPos.xyz, 1);
#endif

    v_World4x4 = float4x4(World[0], World[1], World[2], float4(0, 0, 0, 1));

#if defined(SKINNED)
    int4 boneOffsets = (int4)(input.BoneIndices * 765.01);
    float3x4 AdjustedModelToSkinnedWorldMatrix = 0;

    float4 PosAdjustX = float4(-0, 0, -0, -CurrentPosAdjust.x);
    float4 PosAdjustY = float4(-0, 0, -0, -CurrentPosAdjust.y);
    float4 PosAdjustZ = float4(-0, 0, -0, -CurrentPosAdjust.z);

    // we could optimize a later set of skinning away by adjusting after but need to match the depth pass shader for now or else we get issues
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.x * float3x4(Bones[boneOffsets.x] + PosAdjustX, Bones[boneOffsets.x + 1] + PosAdjustY, Bones[boneOffsets.x + 2] + PosAdjustZ);
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.y * float3x4(Bones[boneOffsets.y] + PosAdjustX, Bones[boneOffsets.y + 1] + PosAdjustY, Bones[boneOffsets.y + 2] + PosAdjustZ);
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.z * float3x4(Bones[boneOffsets.z] + PosAdjustX, Bones[boneOffsets.z + 1] + PosAdjustY, Bones[boneOffsets.z + 2] + PosAdjustZ);
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.w * float3x4(Bones[boneOffsets.w] + PosAdjustX, Bones[boneOffsets.w + 1] + PosAdjustY, Bones[boneOffsets.w + 2] + PosAdjustZ);

    // update world matrix to skinned world matrix
    v_World4x4[0] = AdjustedModelToSkinnedWorldMatrix[0];
    v_World4x4[1] = AdjustedModelToSkinnedWorldMatrix[1];
    v_World4x4[2] = AdjustedModelToSkinnedWorldMatrix[2];
#endif

#if defined(DRAW_IN_WORLDSPACE)
    v_ModelVertexPos = v_VertexPos;
    // update common space vertex position
    v_VertexPos = float4(dot(v_VertexPos, v_World4x4[0]), dot(v_VertexPos, v_World4x4[1]), dot(v_VertexPos, v_World4x4[2]), 1);
#endif

#if defined(LODLANDSCAPE)
    precise float4 WorldVertexPos = mul(v_World4x4, v_VertexPos);
    float2 LodVertexDist = abs(WorldVertexPos.xy - HighDetailRange.xy);
    if (LodVertexDist.x < HighDetailRange.z && LodVertexDist.y < HighDetailRange.w)
    {
        v_VertexPos.z = input.VertexPos.z - ((WorldVertexPos.z / 1e+009) + 230);
    }
#endif

#if defined(SKINNED)
    vsout.ProjVertexPos = mul(ViewProjMatrix, v_VertexPos);
#else
    float4x4 ModelProjMatrix = mul(ViewProjMatrix, v_World4x4);
#if defined(DRAW_IN_WORLDSPACE)
    // this is necessary because simply doing ViewProjMatrix, v_VertexPos (which is in worldspace) causes precision differences from the original bethesda shaders
    vsout.ProjVertexPos = mul(ModelProjMatrix, v_ModelVertexPos);
#else
    vsout.ProjVertexPos = mul(ModelProjMatrix, v_VertexPos);
#endif
#endif

#if defined(LODLANDSCAPE)
    float LODVertexZAdjust = min(1, max(0, (vsout.ProjVertexPos.z - 70000)) * 0.0001);
    vsout.ProjVertexPos.z = LODVertexZAdjust * 0.5 + vsout.ProjVertexPos.z;
#endif

    vsout.TexCoords.xy = input.TexCoords.xy * TexCoordOffset.zw + TexCoordOffset.xy;

#if defined(MULTI_TEXTURE)
    float2 LandBlendTexCoords = vsout.TexCoords.xy * float2(0.0104167, 0.0104167) + LandBlendParams.xy;
    vsout.TexCoords.zw = LandBlendTexCoords * float2(1, -1) + float2(0, 1);
#elif defined(PROJECTED_UV)
    vsout.TexCoords.z = dot(TextureProj[0], v_VertexPos);
    vsout.TexCoords.w = dot(TextureProj[1], v_VertexPos);
#endif

#if defined(WORLD_MAP)
    vsout.WorldMapVertexPos = mul(v_World4x4, v_VertexPos).xyz + WorldMapOverlayParameters.xyz;
#elif defined(DRAW_IN_WORLDSPACE)
    vsout.WorldSpaceVertexPos = v_VertexPos.xyz;
#else
    vsout.ModelSpaceVertexPos = v_VertexPos.xyz;
#endif

#if defined(HAS_COMMON_TRANSFORM)
#if defined(SKINNED)
    float3x4 ModelToSkinnedWorldMatrix = 0;

    ModelToSkinnedWorldMatrix += input.BoneWeights.x * float3x4(Bones[boneOffsets.x], Bones[boneOffsets.x + 1], Bones[boneOffsets.x + 2]);
    ModelToSkinnedWorldMatrix += input.BoneWeights.y * float3x4(Bones[boneOffsets.y], Bones[boneOffsets.y + 1], Bones[boneOffsets.y + 2]);
    ModelToSkinnedWorldMatrix += input.BoneWeights.z * float3x4(Bones[boneOffsets.z], Bones[boneOffsets.z + 1], Bones[boneOffsets.z + 2]);
    ModelToSkinnedWorldMatrix += input.BoneWeights.w * float3x4(Bones[boneOffsets.w], Bones[boneOffsets.w + 1], Bones[boneOffsets.w + 2]);
#endif
#if defined(MODELSPACENORMALS)
#if defined(SKINNED)
    vsout.ModelWorldTransform0 = normalize(ModelToSkinnedWorldMatrix[0].xyz);
    vsout.ModelWorldTransform1 = normalize(ModelToSkinnedWorldMatrix[1].xyz);
    vsout.ModelWorldTransform2 = normalize(ModelToSkinnedWorldMatrix[2].xyz);
#else
    vsout.ModelWorldTransform0 = World[0].xyz;
    vsout.ModelWorldTransform1 = World[1].xyz;
    vsout.ModelWorldTransform2 = World[2].xyz;
#endif
#elif defined(DRAW_IN_WORLDSPACE)
#if defined(SKINNED)
    float3 w_bitangent = normalize(mul(ModelToSkinnedWorldMatrix, bitangent));
    float3 w_tangent = normalize(mul(ModelToSkinnedWorldMatrix, tangent));
    float3 w_normal = normalize(mul(ModelToSkinnedWorldMatrix, normal));
#else
    float3 w_bitangent = mul(v_World4x4, bitangent);
    float3 w_tangent = mul(v_World4x4, tangent);
    float3 w_normal = mul(v_World4x4, normal);
#endif
    // tbn is usually tangent, bitangent, normal but bethesda shaders use btn
    // we want this transposed since the transform is Tangent->X not X->Tangent
    float3x3 w_tbn = transpose(float3x3(w_bitangent, w_tangent, w_normal));
    vsout.TangentWorldTransform0 = w_tbn[0];
    vsout.TangentWorldTransform1 = w_tbn[1];
    vsout.TangentWorldTransform2 = w_tbn[2];
#else
    float3x3 tbn = transpose(float3x3(bitangent, tangent, normal));
    vsout.TangentModelTransform0 = tbn[0];
    vsout.TangentModelTransform1 = tbn[1];
    vsout.TangentModelTransform2 = tbn[2];
#endif
#endif

    // this is done in common space, v_VertexPos will give us correct output
#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    vsout.ViewDirectionVec.xyz = EyePosition - v_VertexPos.xyz;
#endif

#if defined(EYE)
    precise float4 EyeCenter;
    // if (IsRightEye) EyeCenter = RightEyeCenter else EyeCenter = LeftEyeCenter
    EyeCenter.xyz = (RightEyeCenter.xyz - LeftEyeCenter.xyz) * input.IsRightEye + LeftEyeCenter.xyz;
    EyeCenter.w = 1;
    // EYE technique is always drawn in worldspace
    precise float3 WorldEyeCenter = float3(dot(EyeCenter.xyzw, v_World4x4[0].xyzw), dot(EyeCenter.xyzw, v_World4x4[1].xyzw), dot(EyeCenter.xyzw, v_World4x4[2].xyzw));
    // direction from vertex to eye center
    vsout.EyeDirectionVec.xyz = normalize(v_VertexPos.xyz - WorldEyeCenter);
#endif

#if defined(PROJECTED_UV)
    vsout.ProjDir.xyz = TextureProj[2].xyz;
#endif

#if defined(MULTI_TEXTURE)
    vsout.BlendWeight0 = input.BlendWeight0;
    float2 LandAdjustedPos = LandBlendParams.zw - v_VertexPos;
    float LandAdjustedPosLen = length(LandAdjustedPos);
    float OffsetLandAdjustedPosLen = saturate(0.000375601 * (9625.6 - LandAdjustedPosLen));
    vsout.BlendWeight1.w = 1 - OffsetLandAdjustedPosLen;
    vsout.BlendWeight1.xyz = input.BlendWeight1.xyz;
#endif

#if defined(MODELSPACENORMALS)
#if defined(SKINNED)
    float3x3 ModelViewMatrix = mul(ViewMatrix, ModelToSkinnedWorldMatrix);
#else
    float3x3 ModelViewMatrix = mul(ViewMatrix, v_World4x4);
#endif
    vsout.ModelViewTransform0 = ModelViewMatrix[0];
    vsout.ModelViewTransform1 = ModelViewMatrix[1];
    vsout.ModelViewTransform2 = ModelViewMatrix[2];
#else
#if defined(DRAW_IN_WORLDSPACE)
    float3x3 TangentModelViewMatrix = mul(ViewMatrix, w_tbn);
#else
    float3x3 ModelViewMatrix = mul(ViewMatrix, v_World4x4);
    float3x3 TangentModelViewMatrix = mul(ModelViewMatrix, tbn);
#endif
    vsout.TangentViewTransform0 = TangentModelViewMatrix[0];
    vsout.TangentViewTransform1 = TangentModelViewMatrix[1];
    vsout.TangentViewTransform2 = TangentModelViewMatrix[2];
#endif

#if defined(DRAW_IN_WORLDSPACE)
    vsout.WorldVertexPos = v_VertexPos;
#else
    vsout.WorldVertexPos = mul(v_World4x4, v_VertexPos);
#endif


#if defined(DRAW_IN_WORLDSPACE)
    precise float4 v_PrevVertexPos = float4(input.VertexPos.xyz, 1);
#else
    // primarily to catch LODLANDSCAPE edited vertex pos
    precise float4 v_PrevVertexPos = float4(v_VertexPos.xyz, 1);
#endif

#if defined(SKINNED)
    float3x4 ModelToSkinnedPreviousWorldMatrix = 0;

    PosAdjustX = float4(-0, 0, -0, -PreviousPosAdjust.x);
    PosAdjustY = float4(-0, 0, -0, -PreviousPosAdjust.y);
    PosAdjustZ = float4(-0, 0, -0, -PreviousPosAdjust.z);

    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.x * float3x4(PreviousBones[boneOffsets.x] + PosAdjustX, PreviousBones[boneOffsets.x + 1] + PosAdjustY, PreviousBones[boneOffsets.x + 2] + PosAdjustZ);
    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.y * float3x4(PreviousBones[boneOffsets.y] + PosAdjustX, PreviousBones[boneOffsets.y + 1] + PosAdjustY, PreviousBones[boneOffsets.y + 2] + PosAdjustZ);
    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.z * float3x4(PreviousBones[boneOffsets.z] + PosAdjustX, PreviousBones[boneOffsets.z + 1] + PosAdjustY, PreviousBones[boneOffsets.z + 2] + PosAdjustZ);
    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.w * float3x4(PreviousBones[boneOffsets.w] + PosAdjustX, PreviousBones[boneOffsets.w + 1] + PosAdjustY, PreviousBones[boneOffsets.w + 2] + PosAdjustZ);

    vsout.PreviousWorldVertexPos.xyzw =
        float4(dot(v_PrevVertexPos, ModelToSkinnedPreviousWorldMatrix[0]),
            dot(v_PrevVertexPos, ModelToSkinnedPreviousWorldMatrix[1]),
            dot(v_PrevVertexPos, ModelToSkinnedPreviousWorldMatrix[2]),
            1);
#else
    vsout.PreviousWorldVertexPos = mul(float4x4(PreviousWorld[0], PreviousWorld[1], PreviousWorld[2], float4(0, 0, 0, 1)), v_PrevVertexPos);
#endif

    vsout.VertexColor = v_VertexColor;
    vsout.FogParam = GetFog(vsout.ProjVertexPos.xyz, FogParam.x, FogParam.y, FogParam.z, FogParam.w, FogNearColor.xyz, FogFarColor.xyz);

    return vsout;
}