// Skyrim Special Edition - BSLightingShader Common

// techniques 
// 0 None
// 1 Envmap - #define ENVMAP
// 2 Glowmap - #define GLOWMAP
// 3 Parallax - #define PARALLAX
// 4 Facegen - #define FACEGEN  (Face Tint)
// 5 FacegenRGBTint - #define FACEGEN_RGB_TINT (Skin Tint)
// 6 Hair - #define HAIR (Hair Tint)
// 7 ParallaxOcc - #define PARALLAX_OCC
// 8 MTLand - #define MULTI_TEXTURE, #define LANDSCAPE
// 9 LODLand - #define LODLANDSCAPE
// 10 Unknown - Unused (SNOW)
// 11 MultiLayerParallax - #define MULTI_LAYER_PARALLAX, #define ENVMAP
// 12 Tree - #define TREE_ANIM
// 13 LODObj - #define LODOBJECTS
// 14 MultiIndexTriShapeSnow - #define MULTI_INDEX, #define SPARKLE
// 15 LODObjHD - #define LODOBJECTSHD
// 16 Eye - #define EYE
// 17 Unknown - Unused (#define CLOUD, #define INSTANCED)
// 18 LODLandNoise - #define LODLANDSCAPE, #define LODLANDNOISE
// 19 MTLandLODBlend - #define MULTI_TEXTURE, #define LANDSCAPE, #define LOD_LAND_BLEND

// flags
// most flags are unused in VS, reference https://github.com/Nukem9/SkyrimSETest/blob/master/skyrim64_test/src/patches/TES/BSShader/Shaders/BSLightingShader.cpp#L1077
// 1<<0 Vc - #define VC
// 1<<1 Sk - #define SKINNED
// 1<<2 Msn - #define MODELSPACENORMALS
// 1<<9 Spc - #define SPECULAR
// 1<<10 Sss - #define SOFT_LIGHTING
// 1<<11 Rim - #define RIM_LIGHTING
// 1<<12 Bk - #define BACK_LIGHTING
// 1<<13 Sh - #define SHADOW_DIR
// 1<<14 DfSh - #define DEFSHADOW
// 1<<15 Projuv - #define PROJECTED_UV
// 1<<15 DwDecals - #define DEPTH_WRITE_DECALS (HAIR technique only)
// 1<<16 (None) - #define ANISO_LIGHTING
// 1<<17 Aspc - #define AMBIENT_SPECULAR
// 1<<18 Wmap - #define WORLD_MAP
// 1<<19 BaseSnow - #define BASE_OBJECT_IS_SNOW
// 1<<20 Atest - #define DO_ALPHA_TEST
// 1<<21 Snow - #define SNOW
// 1<<22 (None) - #define CHARACTER_LIGHT
// 1<<23 (Aam) - #define ADDITIONAL_ALPHA_MASK

// note: in the game's renderer PARALLAX, PARALLAXOCC, FACEGEN, and FACEGEN_RGB_TINT do not update the eye (view) position so this output will be wrong unless specular is also enabled
// in vertex shader RIM_LIGHTING and AMBIENT_SPECULAR force SPECULAR flag, creating the view direction vector, even though those flags aren't used to generate vertex shader combinations
#if defined(SPECULAR) || defined(RIM_LIGHTING) || defined(AMBIENT_SPECULAR) || defined(ENVMAP) || defined(PARALLAX) || defined(PARALLAX_OCC) || defined(FACEGEN) || defined(FACEGEN_RGB_TINT) || defined(MULTILAYERPARALLAX) || defined(EYE)
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

#if defined(MODELSPACENORMALS) && defined(ANISO_LIGHTING)
#error ANISO_LIGHTING cannot be used with MODELSPACENORMALS as it requires vertex normals
#endif

//#if defined(DEPTH_WRITE_DECALS) && !defined(DO_ALPHA_TEST)
//#error DEPTH_WRITE_DECALS is an extension of DO_ALPHA_TEST and requires that flag to be set
//#endif

#if defined(DEPTH_WRITE_DECALS) && !defined(HAIR)
#error DEPTH_WRITE_DECALS is for the HAIR technique only
#endif

#if defined(PROJECTED_UV) && defined(PARALLAX)
#error PARALLAX technique incompatible with PROJECTED_UV flag due to re-use of texture slot
#endif

#if defined(MODELSPACENORMALS) && defined(PARALLAX)
#error PARALLAX technique incompatible with MODELSPACENORMALS because there is no matrix to convert to tangent space
#endif

#if defined(MODELSPACENORMALS) && defined(MULTI_LAYER_PARALLAX)
#error MULTI_LAYER_PARALLAX technique incompatible with MODELSPACENORMALS because there is no matrix to convert to tangent space
#endif

#if defined(PROJECTED_UV) && defined(MULTI_LAYER_PARALLAX)
#error MULTI_LAYER_PARALLAX technique incomptaible with PROJECTED_UV flag due to re-use of texture slot
#endif

#if defined(PROJECTED_UV) && defined(FACEGEN)
#error FACEGEN technique incompatible with PROJECTED_UV flag due to re-use of texture slot
#endif

#if defined(PROJECTED_UV) && defined(MULTI_TEXTURE)
#error MULTI_TEXTURE technique incompatible with PROJECTED_UV flag due to re-use of texture slot
#endif

#if defined(MODELSPACENORMALS) && defined(MULTI_TEXTURE)
#error MULTI_TEXTURE technique incompatible with MODELSPACENORMALS flag due to re-use of texture slot
#endif

#if defined(MULTI_TEXTURE) && (defined(SOFT_LIGHTING) || defined(RIM_LIGHTING) || defined(BACK_LIGHTING))
#error MULTI_TEXTURE technique incompatible with SOFT/RIM/BACK LIGHTING due to re-use of texture slot
#endif

#if defined(DO_ALPHA_TEST)
cbuffer AlphaTestRefCB : register(b11)
{
    float4 AlphaTestRefCB : packoffset(c0);
}
#endif

// Shared PerFrame buffer
cbuffer PerFrame : register(b12)
{
    row_major float4x4 ViewMatrix : packoffset(c0);
    row_major float4x4 ProjMatrix : packoffset(c4);
    row_major float4x4 ViewProjMatrix : packoffset(c8);
    row_major float4x4 ViewProjMatrixUnjittered : packoffset(c12);
    row_major float4x4 PreviousViewProjMatrixUnjittered : packoffset(c16);
    row_major float4x4 InvProjMatrixUnjittered : packoffset(c20);
    row_major float4x4 ProjMatrixUnjittered : packoffset(c24);
    row_major float4x4 InvViewMatrix : packoffset(c28);
    row_major float4x4 InvViewProjMatrix : packoffset(c32);
    row_major float4x4 InvProjMatrix : packoffset(c36);
    float4   CurrentPosAdjust : packoffset(c40);
    float4   PreviousPosAdjust : packoffset(c41);
    // notes: FirstPersonY seems 1.0 regardless of third/first person, could be LE legacy stuff
    float4   GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW : packoffset(c42);
    float4   DynamicRes_WidthX_HeightY_PreviousWidthZ_PreviousHeightW : packoffset(c43);
    float4   DynamicRes_InvWidthX_InvHeightY_WidthClampZ_HeightClampW : packoffset(c44);
}

// the common transforms and vertex positions don't actually have different names, I chose to do it like this for my sanity
struct VS_OUTPUT
{
    precise float4 ProjVertexPos : SV_POSITION0;
#if defined(MULTI_TEXTURE) || defined(PROJECTED_UV)
    float4 TexCoords : TEXCOORD0;
#else
    float2 TexCoords : TEXCOORD0;
#endif
#if defined(DRAW_IN_WORLDSPACE)
    precise float3 WorldSpaceVertexPos : TEXCOORD4;
#elif defined(WORLD_MAP)
    precise float3 WorldMapVertexPos : TEXCOORD4;
#else
    precise float3 ModelSpaceVertexPos : TEXCOORD4;
#endif
#if defined(HAS_COMMON_TRANSFORM)
#if defined(MODELSPACENORMALS)
    float3 ModelWorldTransform0 : TEXCOORD1;
    float3 ModelWorldTransform1 : TEXCOORD2;
    float3 ModelWorldTransform2 : TEXCOORD3;
#elif defined(DRAW_IN_WORLDSPACE)
    float3 TangentWorldTransform0 : TEXCOORD1;
    float3 TangentWorldTransform1 : TEXCOORD2;
    float3 TangentWorldTransform2 : TEXCOORD3;
#else
    float3 TangentModelTransform0 : TEXCOORD1;
    float3 TangentModelTransform1 : TEXCOORD2;
    float3 TangentModelTransform2 : TEXCOORD3;
#endif
#endif
#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    float3 ViewDirectionVec : TEXCOORD5;
#endif
#if defined(MULTI_TEXTURE)
    float4 BlendWeight0 : TEXCOORD6;
    float4 BlendWeight1 : TEXCOORD7;
#endif
#if defined(EYE)
    float3 EyeDirectionVec : TEXCOORD6;
#endif
#if defined(PROJECTED_UV)
    float3 ProjDir : TEXCOORD7;
#endif
#if defined(MODELSPACENORMALS)
    float3 ModelViewTransform0 : TEXCOORD8;
    float3 ModelViewTransform1 : TEXCOORD9;
    float3 ModelViewTransform2 : TEXCOORD10;
#else
    float3 TangentViewTransform0 : TEXCOORD8;
    float3 TangentViewTransform1 : TEXCOORD9;
    float3 TangentViewTransform2 : TEXCOORD10;
#endif
    precise float4 WorldVertexPos : POSITION1;
    precise float4 PreviousWorldVertexPos : POSITION2;
    float4 VertexColor : COLOR0;
    float4 FogParam : COLOR1;
};

typedef VS_OUTPUT PS_INPUT;