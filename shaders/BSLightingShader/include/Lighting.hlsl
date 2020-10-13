// lighting functions

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