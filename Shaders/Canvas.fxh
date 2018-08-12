/*******************************************************
	ReShade Header: Canvas.fxh
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"

/*******************************************************
	Only used in this header
*******************************************************/
#define CANVAS_TEXTURE_NAME(name) tex##name
#define CANVAS_SAMPLER_NAME(name) s##name
#define CANVAS_DRAW_SHADER_NAME(name) name##draw
#define CANVAS_OVERLAY_SHADER_NAME(name) name##overlay

/*******************************************************
	Functions for drawing,
    not necessary to use them directly
*******************************************************/
namespace Canvas {
    float3 OverlaySampler(float3 image, sampler overlay, float scale, float2 texcoord, int2 offset, float opacity) {
        float3 retVal;
        float3 col = image;
        float fac = 0.0;

        float2 screencoord = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * texcoord;
        float2 overlay_size = (float2)tex2Dsize(overlay, 0) * scale;
        offset.x = clamp(offset.x, 0, BUFFER_WIDTH - overlay_size.x);
        offset.y = clamp(offset.y, 0, BUFFER_HEIGHT - overlay_size.y);
        float2 border_min = (float2)offset;
        float2 border_max = border_min + overlay_size;

        if( screencoord.x <= border_max.x &&
            screencoord.y <= border_max.y &&
            screencoord.x >= border_min.x &&
            screencoord.y >= border_min.y   ) {
                fac = opacity;
                float2 coord_overlay = (screencoord - border_min) / overlay_size;
                col = tex2D(overlay, coord_overlay).rgb;
        }

        return lerp(image, col, fac);
    }
    // aastep()-function taken from page 3 of this tutorial:
    // http://webstaff.itn.liu.se/~stegu/webglshadertutorial/shadertutorial.html
    float aastep(float threshold, float value)
    {
        float afwidth = length(float2(ddx(value), ddy(value)));
        return smoothstep(threshold - afwidth, threshold + afwidth, value);
    }
    float3 DrawCurve(float3 texcolor, float3 pointcolor, float2 pointcoord, float2 texcoord, float threshold) {
        return lerp(pointcolor, texcolor, aastep(threshold, length(texcoord - pointcoord)));
    }
    float3 DrawScale(float3 texcolor, float3 color_begin, float3 color_end, int2 scale_pos, int2 scale_size, float value, float3 color_marker, float2 texcoord, sampler s, float threshold) {
        int2 texSize = tex2Dsize(s, 0);
        
        //Clamp values
        scale_size.x = clamp(scale_size.x, 0, texSize.x);
        scale_size.y = clamp(scale_size.y, 0, texSize.y);
        scale_pos.x = clamp(scale_pos.x, 0, texSize.x - scale_size.x);
        scale_pos.y = clamp(scale_pos.y, 0, texSize.y - scale_size.y);
        
        float2 scalePosFloat = (float2)scale_pos / (float2)scale_size;
        int2 pixelcoord = texcoord * texSize;
        float2 sizeFactor = (float2)scale_size / (float2)texSize;

        if( pixelcoord.x >= scale_pos.x &&
            pixelcoord.x <= scale_pos.x + scale_size.x &&
            pixelcoord.y <= scale_pos.y + scale_size.y &&
            pixelcoord.y >= scale_pos.y ) {
            if(scale_size.y >= scale_size.x) {
                //Vertical scale
                texcolor = lerp(color_begin, color_end, texcoord.y / sizeFactor.y - scalePosFloat.y);
                texcolor = DrawCurve(texcolor, color_marker, float2(texcoord.x, (value + scalePosFloat.y) * sizeFactor.y), texcoord, threshold);
            }
            else {
                //Horizontal scale
                texcolor = lerp(color_begin, color_end, texcoord.x / sizeFactor.x - scalePosFloat.x);
                texcolor = DrawCurve(texcolor, color_marker, float2((value + scalePosFloat.x) * sizeFactor.x, texcoord.y), texcoord, threshold);
            }
        }
        return texcolor;
    }
}

/*******************************************************
	Setting up the canvas:
    - Add uniforms for position and opacity
    - Add texture and sampler for canvas
    - Add function to show the canvas
*******************************************************/
#define CANVAS_SETUP(name, width, height) \
    uniform int2 name##Position < \
        ui_type = "drag"; \
        ui_category = #name; \
        ui_label = "Position"; \
        ui_min = 0; ui_max = BUFFER_WIDTH; \
        ui_step = 1; \
    > = int2(0, 0); \
    uniform float name##Opacity < \
        ui_type = "drag"; \
        ui_category = #name; \
        ui_label = "Opacity"; \
        ui_min = 0.0; ui_max = 1.0; \
        ui_step = 0.01; \
    > = 1.0; \
    texture2D CANVAS_TEXTURE_NAME(name) { Width = width; Height = height; Format = RGBA8; }; \
    sampler2D CANVAS_SAMPLER_NAME(name) { Texture = CANVAS_TEXTURE_NAME(name); }; \
    float3 CANVAS_OVERLAY_SHADER_NAME(name)(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target { \
        float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb; \
        return Canvas::OverlaySampler(backbuffer, CANVAS_SAMPLER_NAME(name), 1.0, texcoord, name##Position, name##Opacity); \
    }  

/*******************************************************
	For drawing
*******************************************************/
#define CANVAS_DRAW_SHADER(name) CANVAS_DRAW_SHADER_NAME(name)(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
#define CANVAS_SET_BACKGROUND(name, color) float3 name = color
#define CANVAS_DRAW_CURVE_XY(name, color, func) name = Canvas::DrawCurve(name, color, float2(texcoord.x, func), float2(texcoord.x, 1.0 - texcoord.y), 0.002)
#define CANVAS_DRAW_CURVE_YX(name, color, func) name = Canvas::DrawCurve(name, color, float2(func, texcoord.y), texcoord, 0.002)
#define CANVAS_DRAW_SCALE(name, color_begin, color_end, scale_pos, scale_size, value, color_marker) name = Canvas::DrawScale(name, color_begin, color_end, scale_pos, scale_size, value, color_marker, float2(texcoord.x, 1.0 - texcoord.y), CANVAS_SAMPLER_NAME(name), 0.002)
#define CANVAS_FINALIZE(name) return name

/*******************************************************
	Add technique to show canvas
*******************************************************/
#define CANVAS_TECHNIQUE(name) \
    technique name { \
        pass { \
            VertexShader = PostProcessVS; \
            PixelShader = CANVAS_DRAW_SHADER_NAME(name); \
            RenderTarget0 = CANVAS_TEXTURE_NAME(name); \
        } \
        pass { \
            VertexShader = PostProcessVS; \
            PixelShader = CANVAS_OVERLAY_SHADER_NAME(name); \
        } \
    }

/*******************************************************
	Example Shader
*******************************************************/
/*
#include "ReShade.fxh"
#include "Canvas.fxh"

uniform float SineFreq<
    ui_type = "drag";
    ui_label = "Sine Frequency";
    ui_min = 0.0; ui_max = 20.0;
    ui_step = 0.01;
> = 6.28;

//Set up canvas
CANVAS_SETUP(TestCanvas, BUFFER_WIDTH/2, BUFFER_HEIGHT/2)

float3 CANVAS_DRAW_SHADER(TestCanvas) {
    //Use BackBuffer as background
    CANVAS_SET_BACKGROUND(TestCanvas, tex2D(ReShade::BackBuffer, texcoord).rgb);
    //Draw a cros in the middle
    CANVAS_DRAW_CURVE_XY(TestCanvas, float3(0.0, 1.0, 0.0), 0.5);
    CANVAS_DRAW_CURVE_YX(TestCanvas, float3(0.0, 1.0, 0.0), 0.5);
    //Draw a sine
    CANVAS_DRAW_CURVE_XY(TestCanvas, float3(1.0, 0.0, 0.0), sin(SineFreq * texcoord.x) * 0.5 + 0.5);
    //return
    CANVAS_FINALIZE(TestCanvas);
}

//Pixelshader that does nothing
float3 CanvasPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    return tex2D(ReShade::BackBuffer, texcoord).rgb;
}

technique Canvas {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = CanvasPS;
    }
}

//Add technique for showing the canvas
CANVAS_TECHNIQUE(TestCanvas)
*/