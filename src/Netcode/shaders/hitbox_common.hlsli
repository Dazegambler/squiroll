struct PSInput {
    float4 pos : SV_Position;
    float3 col : COLOR0;
    uint flags : FLAGS;
    float2 uv : TEXCOORD0;
    float2 thresholds : POSITION1;
};
