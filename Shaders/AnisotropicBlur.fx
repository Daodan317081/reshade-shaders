#include "ReShade.fxh"
#include "Tools.fxh"

#ifndef BLUR_MAX
    #define BLUR_MAX 5.0
#endif

#ifndef UIBlurSteps
    uniform int UIBlurSteps <
        ui_type = "drag";
        ui_min = 1; ui_max = BLUR_MAX;
        ui_step = 1;
    > = 1;
#endif

uniform float UIBlurStrength <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 10.0;
    ui_step = 0.01;
> = 1.0;

uniform int iUIEdgeType <
	ui_type = "combo";
	ui_label = "Edge detection kernel";
	ui_items = "CONV_SOBEL\0CONV_PREWITT\0CONV_SCHARR\0CONV_SOBEL2\0";
> = 0;

uniform int iUIRetVal <
	ui_type = "combo";
    ui_items = "Color\0Blur1\0Blur2\0Edges\0";
> = 0;

float GaussCurve(float i) {
    return exp( -(i*i) / (2 * UIBlurStrength * UIBlurStrength));
}


float3 AnisotropicBlur_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 blur1 = Tools::Convolution::BlurGauss3x3(ReShade::BackBuffer, texcoord);
    float3 blur2 = Tools::Convolution::BlurGauss5x5(ReShade::BackBuffer, texcoord);
    float3 edges = saturate(pow(dot(Tools::Convolution::Edges(ReShade::BackBuffer, texcoord, iUIEdgeType, CONV_MAX), 0.5), UIBlurStrength));

    if(iUIRetVal == 1)
        return blur1;
    if(iUIRetVal == 2)
        return blur2;
    if(iUIRetVal == 3)
        return edges;

    return (color*edges + blur1 + blur2*(1.0-edges)) / 2.0;
}

technique AnisotropicBlur {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = AnisotropicBlur_PS;
	}
}