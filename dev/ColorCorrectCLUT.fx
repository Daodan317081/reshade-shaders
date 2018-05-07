#include "ReShade.fxh"
#include "Tools.fxh"

#ifndef CLUT_TILE_SIZE
    #define CLUT_TILE_SIZE 16
#endif
#ifndef CLUT_NUM_TILES
    #define CLUT_NUM_TILES 16
#endif

uniform float fUICLUTScale <
    ui_type = "drag";
    ui_label = "Overlay Scale";
    ui_min = 0.0; ui_max = 2.0;
> = 1.0;

uniform int iUICreateRedChannel <
    ui_type = "drag";
    ui_label = "Create Red Channel";
    ui_min = 0; ui_max = 1;
> = 1;

uniform int iUICreateGreenChannel <
    ui_type = "drag";
    ui_label = "Create Green Channel";
    ui_min = 0; ui_max = 1;
> = 1;

uniform int iUICreateBlueChannel <
    ui_type = "drag";
    ui_label = "Create Blue Channel";
    ui_min = 0; ui_max = 1;
> = 1;

uniform int iUITex2DType <
    ui_type = "combo";
    ui_label = "Texture lookup type";
    ui_items = "tex2D\0tex2Dfetch\0";
> = 0;

uniform int iUIOverrideBackBuffer <
    ui_type = "drag";
    ui_min = 0; ui_max = 1;
    ui_step = 1;
> = 0;

uniform float3 fUIColor <
	ui_type = "color";
    ui_label = "Color";
> = float3(0.5, 0.5, 0.5);

texture texCreatedCLUT { Width = CLUT_NUM_TILES * CLUT_TILE_SIZE; Height = CLUT_TILE_SIZE; Format = RGBA8; };
sampler2D SamplerCreatedCLUT { Texture = texCreatedCLUT; };

texture texOverlayCLUT_M { Width = CLUT_NUM_TILES * CLUT_TILE_SIZE; Height = CLUT_TILE_SIZE; Format = RGBA8; };
sampler2D SamplerOverlayCLUT_M { Texture = texOverlayCLUT_M; };

int2 GetCLUTCoordsINT(float3 color) {
    int2 image_size = int2(CLUT_TILE_SIZE * CLUT_NUM_TILES, CLUT_TILE_SIZE);
    int coord_red =   (color.r * image_size.x) / CLUT_NUM_TILES;
    int coord_green =  color.g * image_size.y;
    //int coord_blue =    (color.g * image_size.x)
    return int2(coord_red, coord_green);
}


float2 GetCLUTCoordsFLOAT(float3 color) {
    float coord_red =   color.r / CLUT_NUM_TILES;
    float coord_green = color.g;
    float coord_blue =  floor(color.b * CLUT_NUM_TILES) / CLUT_NUM_TILES;

    return saturate(float2(coord_red + coord_blue, coord_green));
}

float3 CLUTCorrect(sampler2D sCLUT, float3 color) {
    if(iUITex2DType == 1)
        return tex2Dfetch(SamplerCreatedCLUT, int4(GetCLUTCoordsINT(color), 0, 0)).rgb;
    else
        return tex2D(SamplerCreatedCLUT, GetCLUTCoordsFLOAT(color)).rgb;
}

float3 CreateNeutralCLUT_PS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float red = frac(texcoord.x * CLUT_NUM_TILES) * iUICreateRedChannel;
    float green = texcoord.y * iUICreateGreenChannel;
    float blue = texcoord.x * iUICreateBlueChannel;

    return float3(red , green, blue);
}

float3 DrawMarkers_PS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(SamplerCreatedCLUT, texcoord.xy).rgb;
    float2 coords = GetCLUTCoordsFLOAT(fUIColor);
    sctpoint markerX = Tools::Draw::NewPoint(WHITE, 4.0.xx, float2(coords.x, texcoord.y));
    color = Tools::Draw::Point(color, markerX, texcoord);
    sctpoint markerY = Tools::Draw::NewPoint(WHITE, 6.0.xx, float2(texcoord.x, coords.y));
    color = Tools::Draw::Point(color, markerY, texcoord);
    return color;
}

float3 OverlayCLUT_PS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color;
    
    if(iUIOverrideBackBuffer == 1)
        color = fUIColor;
    else
        color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    color = Tools::Draw::OverlaySampler(color, SamplerOverlayCLUT_M, fUICLUTScale, texcoord, int2(0, 0), 1.0);
    return color;
}

float3 CLUTCorrect_PS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    return CLUTCorrect(SamplerCreatedCLUT, color);
}

technique CreateCLUT {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = CreateNeutralCLUT_PS;
        RenderTarget = texCreatedCLUT;
    }
}
technique DrawMarkers {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = DrawMarkers_PS;
        RenderTarget = texOverlayCLUT_M;
    }
}
technique ShowLUT {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = OverlayCLUT_PS;
    }
}

technique CLUTCorrect {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = CLUTCorrect_PS;
    }
}
