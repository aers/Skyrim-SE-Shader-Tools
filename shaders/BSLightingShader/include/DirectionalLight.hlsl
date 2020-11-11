float3 GetDirectionalDiffuse(inout psInternalData data, float3 a_lightDirection, float3 a_lightColour, float3 a_shadowColour)
{
    float3 diffuseLight = GetBlinnPhongDiffuse(a_lightDirection, a_shadowColour, data.commonSpaceNormal.xyz);
    
#if defined(SOFT_LIGHTING)
    float cb_LightingProperty_fSubSurfaceLightRolloff = LightingEffectParams.x;
    diffuseLight += GetSoftLighting(a_lightDirection, a_lightColour, data.subsurfaceMask, cb_LightingProperty_fSubSurfaceLightRolloff, data.commonSpaceNormal.xyz);
#endif
    
#if defined(RIM_LIGHTING)
    float cb_LightingProperty_fRimLightPower = LightingEffectParams.y;
    diffuseLight += GetRimLighting(a_lightDirection, a_lightColour, data.subsurfaceMask, cb_LightingProperty_fRimLightPower, data.viewDirection, data.commonSpaceNormal.xyz);
#endif
    
#if defined(BACK_LIGHTING)
    diffuseLight += GetBackLighting(a_lightDirection, a_lightColour, data.backlightMask, data.commonSpaceNormal.xyz);
#endif
    
    return diffuseLight;
}

float3 GetDirectionalSpecular(inout psInternalData data, float3 a_lightDirection, float3 a_lightColour)
{
#if defined(ANISO_LIGHTING)
    return GetAnisotropicLighting(a_lightDirection, a_lightColour, data.specularHardness, data.viewDirection, data.commonSpaceNormal.xyz, data.vertexNormal);
#else
    return GetBlinnPhongSpecular(a_lightDirection, a_lightColour, data.specularHardness, data.viewDirection, data.commonSpaceNormal.xyz);
#endif
}