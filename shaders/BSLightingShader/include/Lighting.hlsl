// lighting functions
void GetLightData(inout psInternalData data)
{
    data.totalLightCount = min(7, NumLightNumShadowLight.x);
    data.shadowLightCount = min(4, NumLightNumShadowLight.y);
    
    // light shadow mask
    // DEFSHADOW: has shadows, could be 0-4
    // SHADOW_DIR: has directional light shadow so no need to check shadowed light count
#if defined(DEFSHADOW) || defined(SHADOW_DIR)
    data.shadowMask = float4(1, 1, 1, 1);
#if !defined(SHADOW_DIR)
    if (shadowLightCount > 0)
    {
#endif
        float2 cb_DynamicRes_Inv = float2(DynamicRes_InvWidthX_InvHeightY_WidthClampZ_HeightClampW.xy);
        float2 cb_DynamicRes = float2(DynamicRes_WidthX_HeightY_PreviousWidthZ_PreviousHeightW.xy);
        float cb_DynamicRes_WidthClamp = DynamicRes_InvWidthX_InvHeightY_WidthClampZ_HeightClampW.z;

        float2 shadowMaskPos = (cb_DynamicRes_Inv.xy * data.input.ProjectedVertexPos.xy * VPOSOffset.xy + VPOSOffset.zw) * cb_DynamicRes.xy;
    
        shadowMaskPos = clamp(float2(0, 0), float2(cb_DynamicRes_WidthClamp, cb_DynamicRes.y), shadowMaskPos);

        data.shadowMask = Sample2D(ShadowMask, shadowMaskPos).xyzw;
#if !defined(SHADOW_DIR)
    }
#endif
#endif
}

// main light functions

// Blinn-Phong diffuse
float3 DirectionalLightDiffuse(float3 vLightDirection, float3 vLightColour, float3 vNormal)
{
    float lightIntensity = saturate(dot(vNormal, vLightDirection));
    return vLightColour * lightIntensity;
}

// Blinn-Phong specular
float3 DirectionalLightSpecular(float3 vLightDirection, float3 vLightColour, float fSpecularHardness, float3 vViewDirection, float3 vNormal)
{
    float3 halfAngle = normalize(vLightDirection + vViewDirection);
    float specIntensity = pow(saturate(dot(halfAngle, vNormal)), fSpecularHardness);

    return vLightColour * specIntensity;
}

float3 AnisotropicSpecular(float3 vLightDirectionN, float3 vLightColour, float fSpecularHardness, float3 vViewDirectionN, float3 vNormal, float3 vVertexNormal)
{
    float3 halfAngle = normalize(vLightDirectionN + vViewDirectionN);
    float3 anisoDir = normalize(vNormal * 0.5 + vVertexNormal);

    float anisoIntensity = 1 - min(1, abs(dot(anisoDir, vLightDirectionN) - dot(anisoDir, halfAngle)));
    float spec = 0.7 * pow(anisoIntensity, fSpecularHardness);

    return vLightColour * spec * max(0, vLightDirectionN.z);
}

// soft (wrap) lighting
float3 SoftLighting(float3 vLightDirection, float3 vLightColor, float3 vSoftMask, float fSoftRolloff, float3 vNormal)
{
    float softIntensity = dot(vNormal, vLightDirection);
    
    // can't be entirely sure what their original code looks like but this generates shader asm that does the same thing
    // generates t * t * (3-2*t) where t = the wrap (NdotL + fSoftRolloff/1 + fSoftRolloff)
    float softWrap = smoothstep(-fSoftRolloff, 1.0, softIntensity);
    float soft = saturate(softWrap - smoothstep(0, 1.0, softIntensity));

    return vLightColor * vSoftMask * soft;
}

// rim lighting
float3 RimLighting(float3 vLightDirectionN, float3 vLightColour, float3 vRimMask, float fRimPower, float3 vViewDirectionN, float3 vNormal)
{
    float NdotV = saturate(dot(vNormal, vViewDirectionN));
    
    float rimIntensity = pow(1 - NdotV, fRimPower);
    float rim = saturate(dot(vViewDirectionN, -vLightDirectionN)) * rimIntensity;

    return vLightColour * vRimMask * rim;
}

float3 BackLighting(float3 vLightDirectionN, float3 vLightColor, float3 vBackMask, float3 vNormal)
{
    float backIntensity = dot(vNormal, -vLightDirectionN);

    return vLightColor * vBackMask * backIntensity;
}

float3 GetDirectionalDiffuse(inout psInternalData data, float3 lightDirection, float3 lightColour, float3 shadowColour)
{
    float3 diffuseLight = DirectionalLightDiffuse(lightDirection, shadowColour, data.commonSpaceNormal.xyz);
    
#if defined(SOFT_LIGHTING)
    float cb_LightingProperty_fSubSurfaceLightRolloff = LightingEffectParams.x;
    diffuseLight += SoftLighting(lightDirection, lightColour, data.subsurfaceMask, cb_LightingProperty_fSubSurfaceLightRolloff, data.commonSpaceNormal.xyz);
#endif
    
#if defined(RIM_LIGHTING)
    float cb_LightingProperty_fRimLightPower = LightingEffectParams.y;
    diffuseLight += RimLighting(lightDirection, lightColour, data.subsurfaceMask, cb_LightingProperty_fRimLightPower, data.viewDirection, data.commonSpaceNormal.xyz);
#endif
    
#if defined(BACK_LIGHTING)
    diffuseLight += BackLighting(lightDirection, lightColour, data.backlightMask, data.commonSpaceNormal.xyz);
#endif
    
    return diffuseLight;
}

float3 GetDirectionalSpecular(inout psInternalData data, float3 lightDirection, float3 lightColour)
{
#if defined(ANISO_LIGHTING)
    return AnisotropicSpecular(lightDirection, lightColour, data.specularHardness, data.viewDirection, data.commonSpaceNormal.xyz, data.vertexNormal);
#else
    return DirectionalLightSpecular(lightDirection, lightColour, data.specularHardness, data.viewDirection, data.commonSpaceNormal.xyz);
#endif
}

void AddDirectionalLight(inout psInternalData data)
{
    // directional light
    float3 dirLightShadowedColour = DirLightColour.xyz;
#if defined(SHADOW_DIR)
    dirLightShadowedColour *= data.shadowMask.x;
#endif
    
    data.diffuseLighting += GetDirectionalDiffuse(data, DirLightDirection.xyz, DirLightColour.xyz, dirLightShadowedColour);
    
    data.specularLighting += GetDirectionalSpecular(data, DirLightDirection.xyz, DirLightColour.xyz);
}

void AddPointLights(inout psInternalData data)
{
    // point lights
    for (int currentLight = 0; currentLight < data.totalLightCount; currentLight++)
    {
#if defined(DEFSHADOW)
        float lightShadow = 1;
        
        if (currentLight < data.shadowLightCount)
        {
            int shadowMaskOffset = (int) dot(ShadowLightMaskSelect.xyzw, M_IdentityMatrix[currentLight].xyzw);
            lightShadow = dot(data.shadowMask.xyzw, M_IdentityMatrix[shadowMaskOffset].xyzw);

        }
#endif
        
        float3 lightColour = PointLightColour[currentLight].xyz;
        float3 lightShadowColour = lightColour;
#if defined(DEFSHADOW)
        lightShadowColour *= lightShadow;
#endif
    
        float3 lightDirection = PointLightPosition[currentLight].xyz - data.input.CommonSpaceVertexPos.xyz;
        float lightRadius = PointLightPosition[currentLight].w;
        float lightAttenuation = 1 - pow(saturate(length(lightDirection) / lightRadius), 2);
        float3 lightDirectionN = normalize(lightDirection);
        
        // note: a vanilla bug is fixed here where soft lighting doesn't use the normalized light direction for point lights
        data.diffuseLighting += lightAttenuation * GetDirectionalDiffuse(data, lightDirectionN, lightColour, lightShadowColour);
        
        data.specularLighting += lightAttenuation * GetDirectionalSpecular(data, lightDirectionN, lightColour);
    }
}

// additional light contributions
void AddDirectionalAmbient(inout psInternalData data)
{
    float3 directionalAmbient = float3(
        dot(DirectionalAmbient[0].xyzw, data.commonSpaceNormal.xyzw),
        dot(DirectionalAmbient[1].xyzw, data.commonSpaceNormal.xyzw),
        dot(DirectionalAmbient[2].xyzw, data.commonSpaceNormal.xyzw)
        );
    
    data.diffuseLighting += directionalAmbient.xyz;
}

void AddEmit(inout psInternalData data)
{
    data.diffuseLighting += EmitColour.xyz;
}

void AddIBL(inout psInternalData data)
{
    data.diffuseLighting += IBLParams.yzw * IBLParams.x;
}

void AddCharacterLight(inout psInternalData data)
{
    float gs_CharacterLightingStrengthPrimary = CharacterLightParams.x;
    float gs_CharacterLightingStrengthSecondary = CharacterLightParams.y;
    float gs_CharacterLightingStrengthLuminance = CharacterLightParams.z;
    float gs_CharacterLightingStrengthMaxLuminance = CharacterLightParams.w;

    float primaryIntensity = saturate(dot(data.viewDirection, data.commonSpaceNormal.xyz));
    // TODO: these constants are probably something simple
    float secondaryIntensity = saturate(dot(float2(0.164399, -0.986394), data.commonSpaceNormal.yz));

    float characterLightingStrength = primaryIntensity * gs_CharacterLightingStrengthPrimary + secondaryIntensity * gs_CharacterLightingStrengthSecondary;
    float noise = Sample2D(ProjectedNoise, float2(1, 1)).x;
    float characterLightingLuminance = clamp(gs_CharacterLightingStrengthLuminance * noise, 0, gs_CharacterLightingStrengthMaxLuminance);
    
    data.diffuseLighting += characterLightingStrength * characterLightingLuminance;
}

void GetAmbientSpecular(inout psInternalData data)
{
    float ambientSpecularIntensity = pow(1 - saturate(dot(data.commonSpaceNormal.xyz, data.viewDirection)), AmbientSpecularTintAndFresnelPower.w);
    float4 commonSpaceNormal_AS = float4(data.commonSpaceNormal.xyz, 0.15);
    float3 ambientSpecularColor = AmbientSpecularTintAndFresnelPower.xyz *
        float3(
            saturate(dot(DirectionalAmbient[0].xyzw, commonSpaceNormal_AS.xyzw)),
            saturate(dot(DirectionalAmbient[1].xyzw, commonSpaceNormal_AS.xyzw)),
            saturate(dot(DirectionalAmbient[2].xyzw, commonSpaceNormal_AS.xyzw))
            );

    data.ambientSpecular = ambientSpecularColor * ambientSpecularIntensity;
}

// additional lighting texture samples
void GetSubsurfaceMask(inout psInternalData data)
{
    data.subsurfaceMask = Sample2D(SubSurface, data.input.TexCoords.xy).xyz;
}

void GetBacklightMask(inout psInternalData data)
{
    data.backlightMask = Sample2D(BackLightMask, data.input.TexCoords.xy).xyz;
}

