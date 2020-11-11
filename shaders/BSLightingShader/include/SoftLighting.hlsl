float3 GetSoftLighting(float3 a_lightDirection, float3 a_lightColour, float3 a_softMask, float a_softRolloff, float3 vNormal)
{
    float softIntensity = dot(vNormal, a_lightDirection);
    
    // can't be entirely sure what their original code looks like but this generates shader asm that does the same thing
    // generates t * t * (3-2*t) where t = the wrap (NdotL + softRolloff/1 + softRolloff)
    float softWrap = smoothstep(-a_softRolloff, 1.0, softIntensity);
    float soft = saturate(softWrap - smoothstep(0, 1.0, softIntensity));

    return a_lightColour * a_softMask * soft;
}

void GetSubsurfaceMask(inout psInternalData data)
{
    data.subsurfaceMask = Sample2D(SubSurface, data.input.TexCoords.xy).xyz;
}