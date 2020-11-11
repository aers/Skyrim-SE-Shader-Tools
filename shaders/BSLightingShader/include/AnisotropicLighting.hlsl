float3 GetAnisotropicLighting(float3 a_lightDirection, float3 a_lightColour, float a_specularHardness, float3 a_viewDirection, float3 a_normal, float3 a_vertexNormal)
{
    float3 halfAngle = normalize(a_lightDirection + a_viewDirection);
    float3 anisoDir = normalize(a_normal * 0.5 + a_vertexNormal);

    float anisoIntensity = 1 - min(1, abs(dot(anisoDir, a_lightDirection) - dot(anisoDir, halfAngle)));
    float spec = 0.7 * pow(anisoIntensity, a_specularHardness);

    return a_lightColour * spec * max(0, a_lightDirection.z);
}