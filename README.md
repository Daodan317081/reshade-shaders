# reshade-shaders
Shaders for ReShade

## [Comic.fx](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/Comic.fx)

![Comic.fx](https://i.imgur.com/qSKbudN.jpg "Comic.fx: Rise of the Tomb Raider")

In order to achieve this look this shader uses different sorts of (configurable) edge detection methods on the color and depth information of the frame. Also, every edge layer can be individually faded in and out with distance. After all the layers are combined the resulting layer can be masked based on the luminosity and saturation of the original color (can be useful to mask the game's UI).

The whole appeal of this shader relys on the depth buffer - so access to it is desperatly needed.

## [ColorIsolation.fx](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/ColorIsolation.fx)

![ColorIsolation.fx](https://i.imgur.com/fTOw9YV.jpg "ColorIsolation.fx: Mirror's Edge Catalyst")

This shader lets the user configure the preferred hue and desaturates everything else. It is also possible to desaturate only the user-defined hue.

## [AspectRatioComposition.fx](https://github.com/Daodan317081/reshade-shaders/blob/master/Shaders/AspectRatioComposition.fx)

Draws a configurable overlay:

- Configurable aspect ratio
- Custom overlay color
- Borders
- Composition grid:
  - Fractions (halfs, thirds, etc.)
  - Golden ratio