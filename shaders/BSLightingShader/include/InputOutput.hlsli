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
    float4 VertexColour : COLOR0;
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
struct VS_OUTPUT
{
    precise float4 ProjectedVertexPos : SV_POSITION0;
#if defined(MULTI_TEXTURE) || defined(PROJECTED_UV)
    float4 TexCoords : TEXCOORD0;
#else
    float2 TexCoords : TEXCOORD0;
#endif
    precise float3 CommonSpaceVertexPos : TEXCOORD4;
#if defined(HAS_COMMON_TRANSFORM)
    float3 CommonSpaceTransform0 : TEXCOORD1;
    float3 CommonSpaceTransform1 : TEXCOORD2;
    float3 CommonSpaceTransform2 : TEXCOORD3;
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
    float3 ProjectionDir : TEXCOORD7;
#endif
    float3 ViewSpaceTransform0 : TEXCOORD8;
    float3 ViewSpaceTransform1 : TEXCOORD9;
    float3 ViewSpaceTransform2 : TEXCOORD10;
    precise float4 WorldVertexPos : POSITION1;
    precise float4 PreviousWorldVertexPos : POSITION2;
    float4 VertexColour : COLOR0;
    float4 FogParam : COLOR1;
};

typedef VS_OUTPUT PS_INPUT;

// PS_OUTPUT
struct PS_OUTPUT
{
    float4 Colour : SV_Target0;
    float4 MotionVector : SV_Target1;
    float4 Normal : SV_Target2;
#if defined(SNOW)
    float4 SnowMask : SV_Target3;
#endif
};