import { typeScale, fontFamilies, fontWeightsToLoad } from '../data/typography';
import { elevationScale } from '../data/elevation';
import type { Direction } from './variables';

/** Load all required fonts for both directions */
export async function loadFonts(direction: Direction): Promise<void> {
  const families: string[] = [];

  if (direction === 'direction-a' || direction === 'both') {
    families.push(fontFamilies.directionA);
  }
  if (direction === 'direction-b' || direction === 'both') {
    families.push(fontFamilies.directionB);
  }

  for (const family of families) {
    for (const weight of fontWeightsToLoad) {
      await figma.loadFontAsync({ family, style: weight });
    }
  }

  // Also load Inter for the UI/reference pages
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
}

/** Create all 15 M3 text styles */
export function createTextStyles(direction: Direction): void {
  const family = direction === 'direction-b' ? fontFamilies.directionB : fontFamilies.directionA;

  for (const token of typeScale) {
    const style = figma.createTextStyle();
    style.name = token.name;
    style.fontName = { family, style: token.weight };
    style.fontSize = token.size;
    style.lineHeight = { value: token.lineHeight, unit: 'PIXELS' };
    style.letterSpacing = { value: token.letterSpacing, unit: 'PIXELS' };
  }
}

/** Create effect styles for all elevation levels */
export function createEffectStyles(direction: Direction): void {
  for (const token of elevationScale) {
    const style = figma.createEffectStyle();
    style.name = token.name;

    const shadow = direction === 'direction-b' ? token.b : token.a;

    if (shadow === null) {
      style.effects = [];
    } else {
      style.effects = [
        {
          type: 'DROP_SHADOW',
          color: { r: 0, g: 0, b: 0, a: shadow.opacity },
          offset: { x: 0, y: shadow.y },
          radius: shadow.blur,
          spread: 0,
          visible: true,
          blendMode: 'NORMAL',
        },
      ];
    }
  }
}

/** Create mobile grid style */
export function createGridStyle(): void {
  const style = figma.createGridStyle();
  style.name = 'mobile/4-column';
  style.layoutGrids = [
    {
      pattern: 'COLUMNS',
      alignment: 'STRETCH',
      count: 4,
      gutterSize: 16,
      offset: 16,
      visible: true,
      color: { r: 1, g: 0, b: 0, a: 0.1 },
    },
  ];
}
