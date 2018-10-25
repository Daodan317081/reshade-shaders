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

    int2 overlayPos = int2(clamp(iUIOverlayPos.x, 0, BUFFER_WIDTH * (1.0 - fUIOverlayScale)),
                           clamp(iUIOverlayPos.y, 0, BUFFER_HEIGHT * (1.0 - fUIOverlayScale)));

    if(vpos.x >= overlayPos.x &&
       vpos.y >= overlayPos.y &&
       vpos.x <  overlayPos.x + BUFFER_WIDTH * fUIOverlayScale &&
       vpos.y <  overlayPos.y + BUFFER_HEIGHT * fUIOverlayScale)
    {
        coord = frac((texcoord - overlayPos / float2(BUFFER_WIDTH, BUFFER_HEIGHT)) / fUIOverlayScale);
    }
    else
    {
        coord = texcoord;
    }

    return tex2D(ReShade::BackBuffer, coord).rgb;
}

technique HotsamplingHelper {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = HotsamplingHelperPS;
        /* RenderTarget = BackBuffer */
    }
}