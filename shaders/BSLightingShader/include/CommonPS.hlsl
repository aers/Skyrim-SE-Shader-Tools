// the compiler will optimize all the unused stuff out
struct psInternalData
{
    PS_INPUT    input;
    float3      viewDirection;
    float3      diffuseColour;
    float       diffuseAlpha;
    float3      normal;
    float       specularPower;
    float3x3    commonSpaceTransform;
    float4      commonSpaceNormal;
    float3      vertexNormal;
    float3      diffuseLighting;
    float3      specularLighting;
    float       specularHardness;
    int         totalLightCount;
    int         shadowLightCount;
    float4      shadowMask;
    float3      subsurfaceMask;
    float3      backlightMask;
};

void GetViewDirection(inout psInternalData data)
{
#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    data.viewDirection = normalize(data.input.ViewDirectionVec);
#else
    // sometimes used for calculations when there's no actual view direction
    data.viewDirection = normalize(float3(1, 1, 1));
#endif
}

void GetDiffuse(inout psInternalData data)
{
    float4 diffuseTexSample = Sample2D(Diffuse, data.input.TexCoords.xy).xyzw;
    data.diffuseColour = diffuseTexSample.xyz;
    data.diffuseAlpha = diffuseTexSample.w;
}

// since specular power is in the normal alpha channel we read it with the same function
void GetNormalsAndSpecularPower(inout psInternalData data)
{
#if defined(MODELSPACENORMALS)
    float3 normalTexSample = Sample2D(Normal, data.input.TexCoords.xy).xyz;
    data.specularPower = Sample2D(Specular, data.input.TexCoords.xy).x;
#else
    float4 normalTexSample = Sample2D(Normal, data.input.TexCoords.xy).xyzw;
    data.specularPower = normalTexSample.w;
#endif    
    data.normal = normalTexSample.xyz * 2.0 - 1.0;
    
    // common space normal   
#if defined(HAS_COMMON_TRANSFORM)
    data.commonSpaceTransform = float3x3(data.input.CommonSpaceTransform0, data.input.CommonSpaceTransform1, data.input.CommonSpaceTransform2);
    data.commonSpaceNormal = float4(normalize(mul(data.commonSpaceTransform, data.normal)), 1);
#else
    data.commonSpaceNormal = float4(data.normal.xyz, 1);
#endif
    
    // vertex normal used for some flags
    // note that the common space transform is the TBN matrix
#if defined(HAS_COMMON_TRANSFORM)
    data.vertexNormal = normalize(float3(data.commonSpaceTransform[0].z, data.commonSpaceTransform[1].z, data.commonSpaceTransform[2].z));
#endif
}

void GetSpecularHardness(inout psInternalData data)
{
    data.specularLighting = SpecularColour.w;
}