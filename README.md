# reshade-shaders
Shaders for [ReShade](https://reshade.me/) written in the [ReShade FX](https://github.com/crosire/reshade-shaders/blob/master/REFERENCE.md) shader language.

## [Comic](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/Comic.fx)

![Comic.fx](https://i.imgur.com/qSKbudN.jpg "Comic.fx: Rise of the Tomb Raider")

In order to achieve this look this shader uses different sorts of (configurable) edge detection methods on the color and depth information of the frame. Also, every edge layer can be individually faded in and out with distance. After all the layers are combined the resulting layer can be masked based on the luminosity and saturation of the original color (can be useful to mask the game's UI).

The whole appeal of this shader relies on the depth buffer - so access to it is desperatly needed.

## [ColorIsolation](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/ColorIsolation.fx)

![ColorIsolation.fx](https://i.imgur.com/fTOw9YV.jpg "ColorIsolation.fx: Mirror's Edge Catalyst")

This shader lets the user configure the preferred hue and desaturates everything else. It is also possible to desaturate only the user-defined hue.

## [AspectRatioComposition](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/AspectRatioComposition.fx)

Draws a configurable overlay:

- Configurable aspect ratio
- Custom overlay color
- Borders
- Composition grid:
  - Fractions (halfs, thirds, etc.)
  - Golden ratio

## [HotsamplingHelper](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/HotsamplingHelper.fx)

Draws a scaled down version of the image onto the screen. Size and position of the overlay is configurable. Useful to check the framing when a program like [SRWE](github.com/dtgDTGdtg/SRWE/) is used for screenshotting.
