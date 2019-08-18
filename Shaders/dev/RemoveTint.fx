
#include "ReShade.fxh"

uniform float fUISpeed <
	ui_type = "slider";
	ui_label = "Speed";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.1;

uniform float fUIThresholdLow <
	ui_type = "slider";
	ui_label = "Clamp Dark Colors";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.0;

uniform float fUIThresholdHigh <
	ui_type = "slider";
	ui_label = "Clamp Bright Colors";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 1.0;

uniform float fUIStrength <
	ui_type = "slider";
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 1.0;

uniform float frametime < source = "frametime"; >;

namespace RemoveTint {

	#ifndef REMOVE_TINT_MIPLEVEL_EXP2
		#define REMOVE_TINT_MIPLEVEL_EXP2 16
	#endif

	texture2D texBackBuffer { Width = BUFFER_WIDTH/REMOVE_TINT_MIPLEVEL_EXP2; Height = BUFFER_HEIGHT/REMOVE_TINT_MIPLEVEL_EXP2; Format = RGBA16F; };
	sampler2D samplerBackBuffer { Texture = texBackBuffer; };

	texture2D texMinRGB { Width = 1; Height = 1; Format = RGBA16F; };
	sampler2D samplerMinRGB { Texture = texMinRGB; };
	texture2D texMaxRGB { Width = 1; Height = 1; Format = RGBA16F; };
	sampler2D samplerMaxRGB { Texture = texMaxRGB; };

	texture2D texMinRGBLastFrame { Width = 1; Height = 1; Format = RGBA16F; };
	sampler2D samplerMinRGBLastFrame { Texture = texMinRGBLastFrame; };
	texture2D texMaxRGBLastFrame { Width = 1; Height = 1; Format = RGBA16F; };
	sampler2D samplerMaxRGBLastFrame { Texture = texMaxRGBLastFrame; };

	void BackBuffer_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 backbuffer : SV_Target0) {
		backbuffer = tex2Dfetch(ReShade::BackBuffer, int4(vpos.xy * REMOVE_TINT_MIPLEVEL_EXP2, 0, 0));
	}

	void MinMaxRGB_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 resultMinRGB : SV_Target0, out float4 resultMaxRGB : SV_Target1) {
		float3 color;
		float4 currentMinRGB = 1.0.rrrr;
		float4 currentMaxRGB = 0.0.rrrr;

		int2 size = ReShade::ScreenSize / REMOVE_TINT_MIPLEVEL_EXP2;

		for(int y = 0; y < size.y; y++) {
			for(int x = 0; x < size.x; x++) {
				color = tex2Dfetch(RemoveTint::samplerBackBuffer, int4(x, y, 0, 0)).rgb;

				currentMaxRGB.r = lerp(currentMaxRGB.r, color.r, step(currentMaxRGB.r, color.r));
				currentMaxRGB.g = lerp(currentMaxRGB.g, color.g, step(currentMaxRGB.g, color.g));
				currentMaxRGB.b = lerp(currentMaxRGB.b, color.b, step(currentMaxRGB.b, color.b));

				currentMinRGB.r = lerp(currentMinRGB.r, color.r, step(color.r, currentMinRGB.r));
				currentMinRGB.g = lerp(currentMinRGB.g, color.g, step(color.g, currentMinRGB.g));
				currentMinRGB.b = lerp(currentMinRGB.b, color.b, step(color.b, currentMinRGB.b));
			}
		}

		float4 lastMinRGB = tex2Dfetch(RemoveTint::samplerMinRGBLastFrame, int4(0, 0, 0, 0));
		float4 lastMaxRGB = tex2Dfetch(RemoveTint::samplerMaxRGBLastFrame, int4(0, 0, 0, 0));

		resultMinRGB = saturate(lerp(lastMinRGB, currentMinRGB, saturate(fUISpeed * frametime * 0.01)));
		resultMaxRGB = saturate(lerp(lastMaxRGB, currentMaxRGB, saturate(fUISpeed * frametime * 0.01)));
		resultMinRGB.a = 1.0;
		resultMaxRGB.a = 1.0;
	}

	void MinMaxRGBBackup_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 currentMinRGB : SV_Target0, out float4 currentMaxRGB : SV_Target1) {
		currentMinRGB = tex2Dfetch(RemoveTint::samplerMinRGB, int4(0, 0, 0, 0));
		currentMaxRGB = tex2Dfetch(RemoveTint::samplerMaxRGB, int4(0, 0, 0, 0));
	}

	float3 Apply_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
		float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
		float3 currentMinRGB = tex2Dfetch(RemoveTint::samplerMinRGB, int4(0, 0, 0, 0)).rgb;
		float3 currentMaxRGB = tex2Dfetch(RemoveTint::samplerMaxRGB, int4(0, 0, 0, 0)).rgb;
		float3 tintRemoved = normalize((color - currentMinRGB) / (currentMaxRGB-currentMinRGB)) * length(color).rrr;
		float luma = dot(color, float3(0.2126, 0.7151, 0.0721));
		float lerpValue = ((smoothstep(0.0, 1.0, 4.0 * luma - (fUIThresholdLow *2.0 - 1.0)) + (1.0 - smoothstep(0.0, 1.0, 4.0 * luma - (2.0 + (1.0 - fUIThresholdHigh)*2.0)))) * 0.5 - 0.5) * 2.0;
		tintRemoved = lerp(color, tintRemoved, lerpValue);
		return saturate(lerp(color, tintRemoved, fUIStrength));
	}
}

technique RemoveTint
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = RemoveTint::BackBuffer_PS;
		RenderTarget = RemoveTint::texBackBuffer;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = RemoveTint::MinMaxRGB_PS;
		RenderTarget0 = RemoveTint::texMinRGB;
		RenderTarget1 = RemoveTint::texMaxRGB;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = RemoveTint::MinMaxRGBBackup_PS;
		RenderTarget0 = RemoveTint::texMinRGBLastFrame;
		RenderTarget1 = RemoveTint::texMaxRGBLastFrame;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = RemoveTint::Apply_PS;
		/* RenderTarget = BackBuffer */
	}
}
