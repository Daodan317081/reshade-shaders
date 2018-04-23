#include "ReShade.fxh"
#include "Tools.fxh"

float3 Vibrance_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target0 {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 color_cmyk = Tools::Color::RGBtoCMYK(color);
    color_cmyk.w = 0.0;
    return Tools::Color::LayerMerge(Tools::Color::LayerMerge(color, Tools::Color::CMYKtoRGB(color_cmyk), LAYER_MODE_HARDLIGHT), color, LAYER_MODE_DODGE);
}


technique Vibrance {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = Vibrance_PS;
    }
}