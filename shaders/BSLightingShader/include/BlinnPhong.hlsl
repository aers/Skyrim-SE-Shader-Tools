// Blinn-Phong diffuse
float3 GetBlingPhongDiffuse(float3 a_lightDirection, float3 a_lightColour, float3 a_normal)
{
    float lightIntensity = saturate(dot(a_normal, a_lightDirection));
    return a_lightColour * lightIntensity;
}

// Blinn-Phong specular
float3 GetBlinnPhongSpecular(float3 a_lightDirection, float3 a_lightColour, float fSpecularHardness, float3 a_viewDirection, float3 a_normal)
{
    float3 halfAngle = normalize(a_lightDirection + a_viewDirection);
    float specIntensity = pow(saturate(dot(halfAngle, a_normal)), fSpecularHardness);

    return a_lightColour * specIntensity;
}