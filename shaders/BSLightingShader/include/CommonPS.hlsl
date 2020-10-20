// the compiler will optimize all the unused stuff out
struct psInternalData
{
    PS_INPUT    input;
    PS_OUTPUT   output;
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
    float3      ambientSpecular;
    float3      outDiffuse;
    float3      outSpecular;
    float3      outColour;
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

void GetOutDiffuse(inout psInternalData data)
{
    data.outDiffuse = data.diffuseLighting * data.diffuseColour * data.input.VertexColour.xyz;
    
    // diffuse clamping
    float gs_fLightingOutputColourClampPostLit = ColourOutputClamp.x;
    
    data.outDiffuse = min(data.outDiffuse, gs_fLightingOutputColourClampPostLit);
   
    data.outColour = data.outDiffuse;
}

void AddOutSpecular(inout psInternalData data)
{
#if defined(SPECULAR)
    float cb_LightingProperty_fSpecularLODFade = MaterialData.y;
    data.outSpecular = data.specularLighting * data.specularPower * cb_LightingProperty_fSpecularLODFade * SpecularColour.xyz;
    
    data.outColour += data.outSpecular;
#endif
#if defined(AMBIENT_SPECULAR)
    data.outColour += data.ambientSpecular;
#endif
    
    float gs_fLightingOutputColourClampPostSpec = ColourOutputClamp.z;
    data.outColour = min(data.outColour, gs_fLightingOutputColourClampPostSpec);
}

void ApplyFog(inout psInternalData data)
{
    float cb_FirstPerson = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.y;
    float cb_AlphaPass = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.z;
    float shouldFogOutput = cb_FirstPerson * cb_AlphaPass;
    float cb_fInvFrameBufferRange = FogColour.w;
    
    float3 fogColour = data.input.FogParam.xyz;
    float fogAmount = data.input.FogParam.w;
    
    float3 foggedColour = lerp(data.outColour, fogColour, fogAmount) * cb_fInvFrameBufferRange;
    
    data.outColour = lerp(data.outColour, foggedColour, shouldFogOutput);
}

void SetOutputColor(inout psInternalData data)
{
    data.output.Colour.xyz = data.outColour;
}

void SetOutputAlpha(inout psInternalData data)
{
#if defined(ADDITIONAL_ALPHA_MASK)
    float outAlpha = data.input.VertexColour.w * data.diffuseAlpha;
#else
    float cb_LightingProperty_fAlpha = MaterialData.z;
    
    float outAlpha = data.input.VertexColour.w * cb_LightingProperty_fAlpha * data.diffuseAlpha;
#endif
    
#if defined(DO_ALPHA_TEST)
    if (outAlpha - AlphaTestRefCB.x < 0)
    {
        discard;
    }
#endif
    
    data.output.Colour.w = outAlpha;
}

void SetOutputMotionVector(inout psInternalData data)
{
    float2 currProjPosition = float2(dot(ViewProjMatrixUnjittered[0].xyzw, data.input.WorldVertexPos.xyzw), dot(ViewProjMatrixUnjittered[1].xyzw, data.input.WorldVertexPos.xyzw)) / dot(ViewProjMatrixUnjittered[3].xyzw, data.input.WorldVertexPos.xyzw);
    float2 prevProjPosition = float2(dot(PreviousViewProjMatrixUnjittered[0].xyzw, data.input.PreviousWorldVertexPos.xyzw), dot(PreviousViewProjMatrixUnjittered[1].xyzw, data.input.PreviousWorldVertexPos.xyzw)) / dot(PreviousViewProjMatrixUnjittered[3].xyzw, data.input.PreviousWorldVertexPos.xyzw);
    float2 motionVector = (currProjPosition - prevProjPosition) * float2(-0.5, 0.5);
    
    if (SSRParams.z > 0.000010)
    {
        data.output.MotionVector.xy = float2(1, 0);
    }
    else
    {
        data.output.MotionVector.xy = motionVector.xy;
    }
    data.output.MotionVector.zw = float2(0, 1);
}

void SetOutputNormal(inout psInternalData data)
{
    float3x3 viewSpaceTransform = float3x3(data.input.ViewSpaceTransform0, data.input.ViewSpaceTransform1, data.input.ViewSpaceTransform2);
    
    float3 viewSpaceNormal = normalize(mul(viewSpaceTransform, data.normal.xyz));
    viewSpaceNormal.z = max(0.001, sqrt(viewSpaceNormal.z * -8 + 8));
    
    data.output.Normal.xy = float2(0.5, 0.5) + (viewSpaceNormal.xy / viewSpaceNormal.z);
    data.output.Normal.z = 0;
}

void SetOutputSpecMask(inout psInternalData data)
{
    float cb_SpecMaskBegin = SSRParams.x;
    float cb_SpecMaskEnd = SSRParams.y;
    float gs_fSpecularLODFade = SSRParams.w;

    data.output.Normal.w = gs_fSpecularLODFade * smoothstep(cb_SpecMaskBegin - 0.000010, cb_SpecMaskEnd, data.specularPower);
}

void DoAAMTest(inout psInternalData data)
{
    float cb_LightingProperty_fAlpha = MaterialData.z;
    uint2 projVertexPosTrunc = (uint2) data.input.ProjectedVertexPos.xy;

    // 0xC - 0b1100
    // 0x3 - 0b0011
    uint AAMIndex = (projVertexPosTrunc.x << 2) & 0xC | (projVertexPosTrunc.y) & 0x3;

    float AAM = cb_LightingProperty_fAlpha - AAMMatrix[AAMIndex];
    
    if (AAM < 0)
    {
        discard;
    }
}