// VS_INPUT
struct VS_INPUT
{
    precise float4 VertexPos : POSITION0;
    float2 TexCoords : TEXCOORD0;
#if !defined(MODELSPACENORMALS)
    float4 Normal : NORMAL0;
    float4 Binormal : BINORMAL0;
#endif
#if defined(VC)
    float4 VertexColor : COLOR0;
#endif
#if defined(MULTI_TEXTURE)
    float4 BlendWeight0 : TEXCOORD2;
    float4 BlendWeight1 : TEXCOORD3;
#endif
#if defined(SKINNED)
    float4 BoneWeights : BLENDWEIGHT0;
    float4 BoneIndices : BLENDINDICES0;
#endif
#if defined(EYE)
    float IsRightEye : TEXCOORD2;
#endif
};

// VS_OUTPUT/PS_INPUT
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

// PS_OUTPUT
struct PS_OUTPUT
{
    float4 Color : SV_Target0;
    float4 MotionVector : SV_Target1;
    float4 Normal : SV_Target2;
#if defined(SNOW)
    float4 SnowMask : SV_Target3;
#endif
};