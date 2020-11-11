void AddCharacterLighting(inout psInternala_data a_data)
{
    float gs_CharacterLightingStrengthPrimary = CharacterLightParams.x;
    float gs_CharacterLightingStrengthSecondary = CharacterLightParams.y;
    float gs_CharacterLightingStrengthLuminance = CharacterLightParams.z;
    float gs_CharacterLightingStrengthMaxLuminance = CharacterLightParams.w;

    float primaryIntensity = saturate(dot(a_data.viewDirection, a_data.commonSpaceNormal.xyz));
    // TODO: these constants are probably something simple
    float secondaryIntensity = saturate(dot(float2(0.164399, -0.986394), a_data.commonSpaceNormal.yz));

    float characterLightingStrength = primaryIntensity * gs_CharacterLightingStrengthPrimary + secondaryIntensity * gs_CharacterLightingStrengthSecondary;
    float noise = Sample2D(ProjectedNoise, float2(1, 1)).x;
    float characterLightingLuminance = clamp(gs_CharacterLightingStrengthLuminance * noise, 0, gs_CharacterLightingStrengthMaxLuminance);
    
    a_data.diffuseLighting += characterLightingStrength * characterLightingLuminance;
}