#include "ReShade.fxh"

uniform int2 iUIOverlayPos <
	ui_type = "drag";
	ui_label = "Overlay Position";
	ui_min = 0; ui_max = BUFFER_WIDTH;
	ui_step = 1;
> = int2(0, 0);

uniform float fUIOverlayScale <
    ui_type = "drag";
    ui_label = "Overlay Scale";
    ui_min = 0.1; ui_max = 1.0;
    ui_step = 0.01;
> = 0.2;

float3 HotsamplingHelperPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float2 coord;

    if(texcoord.x >= (iUIOverlayPos.x / BUFFER_WIDTH) &&
       texcoord.y >= (iUIOverlayPos.y / BUFFER_HEIGHT) &&
       texcoord.x <  (iUIOverlayPos.x / BUFFER_WIDTH) + fUIOverlayScale &&
       texcoord.y <  (iUIOverlayPos.y / BUFFER_HEIGHT + fUIOverlayScale))
    {
        coord = frac((texcoord - iUIOverlayPos / float2(BUFFER_WIDTH, BUFFER_HEIGHT)) / fUIOverlayScale);
    }
    else
    {
        coord = texcoord;
    }

    return tex2D(ReShade::BackBuffer, coord).rgb;
}

technique HotsamplingHelper2 {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = HotsamplingHelperPS;
        /* RenderTarget = BackBuffer */
    }
}