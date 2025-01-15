struct PSInput {
    float4 pos : SV_Position;
    float4 col : COLOR0;
    float2 uv : TEXCOORD0;
    float2 thresholds : POSITION1;
    uint flags : FLAGS;
};
