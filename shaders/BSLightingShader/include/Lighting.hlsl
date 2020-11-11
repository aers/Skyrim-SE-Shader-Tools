#include "AnisotropicLighting.hlsl"
#include "BackLighting.hlsl"
#include "CharacterLighting.hlsl"
#include "RimLighting.hlsl"
#include "SoftLighting.hlsl"

#include "DirectionalLight.hlsl"
#include "PointLight.hlsl"

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




