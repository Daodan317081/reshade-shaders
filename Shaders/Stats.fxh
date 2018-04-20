/*******************************************************
	ReShade Header: Stats
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"

#ifndef STATS_MIPLEVEL
    #define STATS_MIPLEVEL 7.0
#endif

texture2D shared_texStats { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels =  STATS_MIPLEVEL; };
sampler2D shared_SamplerStats { Texture = shared_texStats; };

texture2D shared_texStatsAvgColor { Format = RGBA8; };
sampler2D shared_SamplerStatsAvgColor { Texture = shared_texStatsAvgColor; };

texture2D shared_texStatsAvgLuma { Format = R16F; };
sampler2D shared_SamplerStatsAvgLuma { Texture = shared_texStatsAvgLuma; };

texture2D shared_texStatsAvgColorTemp { Format = R16F; };
sampler2D shared_SamplerStatsAvgColorTemp { Texture = shared_texStatsAvgColorTemp; };