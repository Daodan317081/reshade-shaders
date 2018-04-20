#include "ReShade.fxh"
#include "Include/Functions.fxh"
#include "Include/Color.fxh"

#define GOLDEN_RATIO 1.6180339887
#define INV_GOLDEN_RATIO  1.0 / 1.6180339887
#define MOV_LEFT 1
#define MOV_DOWN 2
#define MOV_RIGHT 3
#define MOV_UP 4

uniform int UIGridType <
	ui_type = "combo";
	ui_label = "Grid Type";
	ui_items = "Center Lines\0Thirds\0Fifths\0Golden Ratio\0Diagonals\0Fibonacci Spiral\0";
> = 0;

uniform float4 UIGridColor <
	ui_type = "color";
    ui_label = "Grid Color";
> = float4(0.0, 0.0, 0.0, 1.0);

uniform float UIGridLineWidth <
	ui_type = "drag";
    ui_label = "Grid Line Width";
    ui_min = 0.0; ui_max = 5.0;
    ui_steps = 0.01;
> = 1.0;

uniform float2 UISpiralCenter <
	ui_type = "drag";
    ui_label = "Spiral Center";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
> = float2(INV_GOLDEN_RATIO, INV_GOLDEN_RATIO);

uniform int UISpiralSteps <
    ui_type = "drag";
    ui_min = 0; ui_max = 30;
    ui_step = 1;
> = 20;

uniform int UISpiralMov <
    ui_type = "drag";
    ui_min = 1; ui_max = 4;
    ui_step = 1;
> = 2;

uniform float UISpiralRotation <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 360.0;
    ui_step = 90.0;
> = 0.0;

uniform float UISpiralScale <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.001;
> = 1.0;


float3 DrawCenterLines(float3 background, float3 gridColor, float lineWidth, float2 texcoord) {
    float3 result;    

    sctpoint lineV1 = Functions::NewPoint(gridColor, lineWidth, float2(0.5, texcoord.y));
    sctpoint lineH1 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 0.5));
    
    result = Functions::DrawPoint(background, lineV1, texcoord);
    result = Functions::DrawPoint(result, lineH1, texcoord);

    return result;
}

float3 DrawThirds(float3 background, float3 gridColor, float lineWidth, float2 texcoord) {
    float3 result;    

    sctpoint lineV1 = Functions::NewPoint(gridColor, lineWidth, float2(1.0 / 3.0, texcoord.y));
    sctpoint lineV2 = Functions::NewPoint(gridColor, lineWidth, float2(2.0 / 3.0, texcoord.y));

    sctpoint lineH1 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 1.0 / 3.0));
    sctpoint lineH2 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 2.0 / 3.0));
    
    result = Functions::DrawPoint(background, lineV1, texcoord);
    result = Functions::DrawPoint(result, lineV2, texcoord);
    result = Functions::DrawPoint(result, lineH1, texcoord);
    result = Functions::DrawPoint(result, lineH2, texcoord);

    return result;
}

float3 DrawFifths(float3 background, float3 gridColor, float lineWidth, float2 texcoord) {
    float3 result;    

    sctpoint lineV1 = Functions::NewPoint(gridColor, lineWidth, float2(1.0 / 5.0, texcoord.y));
    sctpoint lineV2 = Functions::NewPoint(gridColor, lineWidth, float2(2.0 / 5.0, texcoord.y));
    sctpoint lineV3 = Functions::NewPoint(gridColor, lineWidth, float2(3.0 / 5.0, texcoord.y));
    sctpoint lineV4 = Functions::NewPoint(gridColor, lineWidth, float2(4.0 / 5.0, texcoord.y));

    sctpoint lineH1 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 1.0 / 5.0));
    sctpoint lineH2 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 2.0 / 5.0));
    sctpoint lineH3 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 3.0 / 5.0));
    sctpoint lineH4 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 4.0 / 5.0));
    
    result = Functions::DrawPoint(background, lineV1, texcoord);
    result = Functions::DrawPoint(result, lineV2, texcoord);
    result = Functions::DrawPoint(result, lineV3, texcoord);
    result = Functions::DrawPoint(result, lineV4, texcoord);
    result = Functions::DrawPoint(result, lineH1, texcoord);
    result = Functions::DrawPoint(result, lineH2, texcoord);
    result = Functions::DrawPoint(result, lineH3, texcoord);
    result = Functions::DrawPoint(result, lineH4, texcoord);

    return result;
}

float3 DrawGoldenRatio(float3 background, float3 gridColor, float lineWidth, float2 texcoord) {
    float3 result;    

    sctpoint lineV1 = Functions::NewPoint(gridColor, lineWidth, float2(1.0 / GOLDEN_RATIO, texcoord.y));
    sctpoint lineV2 = Functions::NewPoint(gridColor, lineWidth, float2(1.0 - 1.0 / GOLDEN_RATIO, texcoord.y));

    sctpoint lineH1 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 1.0 / GOLDEN_RATIO));
    sctpoint lineH2 = Functions::NewPoint(gridColor, lineWidth, float2(texcoord.x, 1.0 - 1.0 / GOLDEN_RATIO));
    
    result = Functions::DrawPoint(background, lineV1, texcoord);
    result = Functions::DrawPoint(result, lineV2, texcoord);
    result = Functions::DrawPoint(result, lineH1, texcoord);
    result = Functions::DrawPoint(result, lineH2, texcoord);

    return result;
}

float3 DrawDiagonals(float3 background, float3 gridColor, float lineWidth, float2 texcoord) {
    float3 result;    
    float slope = (float)BUFFER_WIDTH / (float)BUFFER_HEIGHT;

    sctpoint line1 = Functions::NewPoint(gridColor, lineWidth,    float2(texcoord.x, texcoord.x * slope));
    sctpoint line2 = Functions::NewPoint(gridColor, lineWidth,  float2(texcoord.x, 1.0 - texcoord.x * slope));
    sctpoint line3 = Functions::NewPoint(gridColor, lineWidth,   float2(texcoord.x, (1.0 - texcoord.x) * slope));
    sctpoint line4 = Functions::NewPoint(gridColor, lineWidth,  float2(texcoord.x, texcoord.x * slope + 1.0 - slope));
    
    result = Functions::DrawPoint(background, line1, texcoord);
    result = Functions::DrawPoint(result, line2, texcoord);
    result = Functions::DrawPoint(result, line3, texcoord);
    result = Functions::DrawPoint(result, line4, texcoord);

    return result;
}

float3 DrawCircle(float3 background, float3 gridColor, float2 pos, float radius, float rotation, float circleLen, float lineWidth, float2 texcoord) {
    float3 result;    
    float2 coord = texcoord;

    float2 centerPix = pos * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 coordPix = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float2 vecPix = coordPix - centerPix;

    float lenPix = length(vecPix);
    float diffPix = lenPix - radius;

    float vecAngle = 0.0;
    float tmp = abs( degrees(asin(vecPix.y / lenPix)));
    if(vecPix.x >= 0.0 && vecPix.y >= 0.0)
        vecAngle = tmp;
    if(vecPix.x < 0.0 && vecPix.y >= 0.0)
        vecAngle = 180.0 - tmp;
    if(vecPix.x < 0.0 && vecPix.y < 0.0)
        vecAngle = 180.0 + tmp;
    if(vecPix.x >= 0.0 && vecPix.y < 0.0)
        vecAngle = 360.0 - tmp;

    vecAngle += rotation;
    if(vecAngle > 360.0)
        vecAngle -= 360.0;

    if(!(diffPix <= lineWidth && diffPix > 0.0))
        coord = -1.0.xx;

    if(vecAngle < (360.0-circleLen))
        coord = -1.0.xx;

    sctpoint lineV1 = Functions::NewPoint(gridColor, lineWidth, coord);
    
    result = Functions::DrawPoint(background, lineV1, texcoord);

    return result;
}

float3 DrawFibonacciSpiral(float3 background, float3 gridColor, float2 pos, int steps, float lineWidth, float2 texcoord) {
    float3 result;
    float2 pixelSize = ReShade::PixelSize;
    
    pos *= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float radius_1 = 1.0;
    float radius_0 = 0.0;
    float radius_new = 1.0;
    float rotation;

    int posChange = UISpiralMov;

    if(posChange == 1)
        rotation = 270.0;
    else if(posChange == 2)
        rotation = 0.0;
    else if(posChange == 3)
        rotation = 90.0;
    else
        rotation = 180.0;

    [loop]
    for(int i = 0; i < steps; i++) {
        result = DrawCircle(background, gridColor, pos * pixelSize, radius_new, rotation, 90.0, UIGridLineWidth, texcoord);

        if(posChange == MOV_DOWN) {
            pos.y += radius_0;
            posChange = MOV_RIGHT;
        }
        else if(posChange == MOV_LEFT) {
            pos.x -= radius_0;
            posChange = MOV_DOWN;
        }
        else if(posChange == MOV_RIGHT) {
            pos.x += radius_0;
            posChange = MOV_UP;
        }
        else /*if(posChange == MOV_UP)*/ {
            pos.y -= radius_0;
            posChange = MOV_LEFT;
        }

        radius_new = radius_0 + radius_1;
        radius_0 = radius_1;
        radius_1 = radius_new;

        rotation += 90.0;
        if(rotation > 360.0)
            rotation -= 360.0;



        if(length(result - gridColor) < 0.01)
            break;
    }

    return result;
}

float3 Composition_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result;

    if(UIGridType == 0)
        result = DrawCenterLines(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    else if(UIGridType == 1)
        result = DrawThirds(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    else if(UIGridType == 2)
        result = DrawFifths(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    else if(UIGridType == 3)
        result = DrawGoldenRatio(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    else if(UIGridType == 4)
        result = DrawDiagonals(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    else if(UIGridType == 5)
        result = DrawFibonacciSpiral(background, UIGridColor.rgb, UISpiralCenter, UISpiralSteps, UIGridLineWidth, texcoord * UISpiralScale);
    else
        result = background;

    return lerp(background, result, UIGridColor.w);
}

float3 CenterLines_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result = DrawCenterLines(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    return lerp(background, result, UIGridColor.w);
}
float3 Thirds_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result = DrawThirds(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    return lerp(background, result, UIGridColor.w);
}
float3 Fifths_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result = DrawFifths(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    return lerp(background, result, UIGridColor.w);
}
float3 GoldenRatio_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result = DrawGoldenRatio(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    return lerp(background, result, UIGridColor.w);
}
float3 Diagonals_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result = DrawDiagonals(background, UIGridColor.rgb, UIGridLineWidth, texcoord);
    return lerp(background, result, UIGridColor.w);
}
float3 Fibonacci_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result = DrawFibonacciSpiral(background, UIGridColor.rgb, UISpiralCenter, UISpiralSteps, UIGridLineWidth, texcoord * UISpiralScale);
    return lerp(background, result, UIGridColor.w);
}

technique Composition
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Composition_PS;
	}
}
technique CompositionCeterLines
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = CenterLines_PS;
	}
}
technique CompositionThirds
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Thirds_PS;
	}
}
technique CompositionFifths
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Fifths_PS;
	}
}
technique CompositionGoldenRatio
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = GoldenRatio_PS;
	}
}
technique CompositionDiagonals
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Diagonals_PS;
	}
}
technique CompositionFibonacci
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Fibonacci_PS;
	}
}