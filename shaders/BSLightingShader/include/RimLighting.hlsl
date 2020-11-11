float3 GetRimLighting(float3 a_lightDirection, float3 a_lightColour, float3 a_rimMask, float a_rimPower, float3 a_viewDirection, float3 a_normal)
{
    float NdotV = saturate(dot(a_normal, a_viewDirection));
    
    float rimIntensity = pow(1 - NdotV, a_rimPower);
    float rim = saturate(dot(a_viewDirection, -a_lightDirection)) * rimIntensity;

    return a_lightColour * a_rimMask * rim;
}