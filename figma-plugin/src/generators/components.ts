import { hexToFigmaRgb } from '../utils/color';
import { fontFamilies } from '../data/typography';
import type { Direction } from './variables';

function getFont(direction: Direction): string {
  return direction === 'direction-b' ? fontFamilies.directionB : fontFamilies.directionA;
}

function createButtonComponent(
  name: string,
  fillColor: RGB,
  textColor: RGB,
  radius: number,
  font: string,
  hasBorder: boolean = false,
  borderColor?: RGB,
): ComponentNode {
  const component = figma.createComponent();
  component.name = name;
  component.resize(200, 48);
  component.layoutMode = 'HORIZONTAL';
  component.primaryAxisAlignItems = 'CENTER';
  component.counterAxisAlignItems = 'CENTER';
  component.paddingLeft = 16;
  component.paddingRight = 16;
  component.cornerRadius = radius;
  component.fills = [{ type: 'SOLID', color: fillColor }];

  if (hasBorder && borderColor) {
    component.strokes = [{ type: 'SOLID', color: borderColor }];
    component.strokeWeight = 1;
  }

  const label = figma.createText();
  label.fontName = { family: font, style: 'Medium' };
  label.fontSize = 14;
  label.lineHeight = { value: 20, unit: 'PIXELS' };
  label.characters = 'Button Label';
  label.fills = [{ type: 'SOLID', color: textColor }];
  component.appendChild(label);

  return component;
}

function createCardComponent(
  name: string,
  fillColor: RGB,
  radius: number,
  hasBorder: boolean = false,
  borderColor?: RGB,
  shadowY?: number,
  shadowBlur?: number,
  shadowOpacity?: number,
): ComponentNode {
  const component = figma.createComponent();
  component.name = name;
  component.resize(343, 120);
  component.layoutMode = 'VERTICAL';
  component.paddingTop = 16;
  component.paddingBottom = 16;
  component.paddingLeft = 16;
  component.paddingRight = 16;
  component.itemSpacing = 8;
  component.cornerRadius = radius;
  component.fills = [{ type: 'SOLID', color: fillColor }];

  if (hasBorder && borderColor) {
    component.strokes = [{ type: 'SOLID', color: borderColor }];
    component.strokeWeight = 1;
  }

  if (shadowY !== undefined && shadowBlur !== undefined && shadowOpacity !== undefined) {
    component.effects = [
      {
        type: 'DROP_SHADOW',
        color: { r: 0, g: 0, b: 0, a: shadowOpacity },
        offset: { x: 0, y: shadowY },
        radius: shadowBlur,
        spread: 0,
        visible: true,
        blendMode: 'NORMAL',
      },
    ];
  }

  return component;
}

export function createComponentsPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🧩 Components';

  const font = getFont(direction);
  const isA = direction !== 'direction-b';

  const primaryFill = isA ? hexToFigmaRgb('#5E8A60') : hexToFigmaRgb('#1A6B6A');
  const onPrimary: RGB = { r: 1, g: 1, b: 1 };
  const secondaryContainer = isA ? hexToFigmaRgb('#F2DCD9') : hexToFigmaRgb('#F5E6C8');
  const onSecondaryContainer = isA ? hexToFigmaRgb('#7D4A43') : hexToFigmaRgb('#8A6408');
  const surface: RGB = { r: 1, g: 1, b: 1 };
  const surfaceContainer = isA ? hexToFigmaRgb('#F0ECE6') : hexToFigmaRgb('#F0F0EE');
  const onSurface = isA ? hexToFigmaRgb('#2D2A26') : hexToFigmaRgb('#1C1C1B');
  const outline = isA ? hexToFigmaRgb('#C5BDB3') : hexToFigmaRgb('#BDBDB8');
  const outlineVariant = isA ? hexToFigmaRgb('#E0DAD2') : hexToFigmaRgb('#DDDDD9');

  const radiusSm = isA ? 12 : 8;
  const radiusMd = isA ? 16 : 12;
  const radiusFull = 9999;

  const shadowConfig = isA
    ? { y: 1, blur: 6, opacity: 0.08 }
    : { y: 1, blur: 3, opacity: 0.12 };

  const container = figma.createFrame();
  container.name = 'Components';
  container.layoutMode = 'VERTICAL';
  container.primaryAxisSizingMode = 'AUTO';
  container.counterAxisSizingMode = 'AUTO';
  container.itemSpacing = 60;
  container.paddingTop = 80;
  container.paddingLeft = 80;
  container.paddingRight = 80;
  container.paddingBottom = 80;
  container.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.98, b: 0.97 } }];
  page.appendChild(container);

  // --- Buttons ---
  const btnSection = figma.createFrame();
  btnSection.name = 'Buttons';
  btnSection.layoutMode = 'VERTICAL';
  btnSection.primaryAxisSizingMode = 'AUTO';
  btnSection.counterAxisSizingMode = 'AUTO';
  btnSection.itemSpacing = 16;
  btnSection.fills = [];
  container.appendChild(btnSection);

  const btnTitle = figma.createText();
  btnTitle.fontName = { family: 'Inter', style: 'Bold' };
  btnTitle.fontSize = 20;
  btnTitle.characters = 'Buttons';
  btnTitle.fills = [{ type: 'SOLID', color: onSurface }];
  btnSection.appendChild(btnTitle);

  const btnRow = figma.createFrame();
  btnRow.name = 'button-variants';
  btnRow.layoutMode = 'HORIZONTAL';
  btnRow.primaryAxisSizingMode = 'AUTO';
  btnRow.counterAxisSizingMode = 'AUTO';
  btnRow.itemSpacing = 16;
  btnRow.fills = [];
  btnSection.appendChild(btnRow);

  const primaryBtn = createButtonComponent('Type=Primary', primaryFill, onPrimary, radiusSm, font);
  btnRow.appendChild(primaryBtn);

  const secondaryBtn = createButtonComponent('Type=Secondary', secondaryContainer, onSecondaryContainer, radiusSm, font);
  btnRow.appendChild(secondaryBtn);

  const textBtn = createButtonComponent('Type=Text', { r: 0, g: 0, b: 0 }, primaryFill, radiusSm, font);
  textBtn.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0 }];
  btnRow.appendChild(textBtn);

  figma.combineAsVariants([primaryBtn, secondaryBtn, textBtn], btnRow);

  // --- Cards ---
  const cardSection = figma.createFrame();
  cardSection.name = 'Cards';
  cardSection.layoutMode = 'VERTICAL';
  cardSection.primaryAxisSizingMode = 'AUTO';
  cardSection.counterAxisSizingMode = 'AUTO';
  cardSection.itemSpacing = 16;
  cardSection.fills = [];
  container.appendChild(cardSection);

  const cardTitle = figma.createText();
  cardTitle.fontName = { family: 'Inter', style: 'Bold' };
  cardTitle.fontSize = 20;
  cardTitle.characters = 'Cards';
  cardTitle.fills = [{ type: 'SOLID', color: onSurface }];
  cardSection.appendChild(cardTitle);

  const cardRow = figma.createFrame();
  cardRow.name = 'card-variants';
  cardRow.layoutMode = 'HORIZONTAL';
  cardRow.primaryAxisSizingMode = 'AUTO';
  cardRow.counterAxisSizingMode = 'AUTO';
  cardRow.itemSpacing = 16;
  cardRow.fills = [];
  cardSection.appendChild(cardRow);

  const elevatedCard = createCardComponent('Type=Elevated', surface, radiusMd, false, undefined, shadowConfig.y, shadowConfig.blur, shadowConfig.opacity);
  cardRow.appendChild(elevatedCard);

  const outlinedCard = createCardComponent('Type=Outlined', surface, radiusMd, true, outlineVariant);
  cardRow.appendChild(outlinedCard);

  const filledCard = createCardComponent('Type=Filled', surfaceContainer, radiusMd);
  cardRow.appendChild(filledCard);

  figma.combineAsVariants([elevatedCard, outlinedCard, filledCard], cardRow);

  // --- Chips ---
  const chipSection = figma.createFrame();
  chipSection.name = 'Chips';
  chipSection.layoutMode = 'VERTICAL';
  chipSection.primaryAxisSizingMode = 'AUTO';
  chipSection.counterAxisSizingMode = 'AUTO';
  chipSection.itemSpacing = 16;
  chipSection.fills = [];
  container.appendChild(chipSection);

  const chipTitle = figma.createText();
  chipTitle.fontName = { family: 'Inter', style: 'Bold' };
  chipTitle.fontSize = 20;
  chipTitle.characters = 'Chips';
  chipTitle.fills = [{ type: 'SOLID', color: onSurface }];
  chipSection.appendChild(chipTitle);

  const chipRow = figma.createFrame();
  chipRow.name = 'chip-variants';
  chipRow.layoutMode = 'HORIZONTAL';
  chipRow.primaryAxisSizingMode = 'AUTO';
  chipRow.counterAxisSizingMode = 'AUTO';
  chipRow.itemSpacing = 12;
  chipRow.fills = [];
  chipSection.appendChild(chipRow);

  const assistChip = figma.createComponent();
  assistChip.name = 'Type=Assist';
  assistChip.resize(100, 32);
  assistChip.layoutMode = 'HORIZONTAL';
  assistChip.primaryAxisAlignItems = 'CENTER';
  assistChip.counterAxisAlignItems = 'CENTER';
  assistChip.paddingLeft = 16;
  assistChip.paddingRight = 16;
  assistChip.cornerRadius = radiusFull;
  assistChip.fills = [{ type: 'SOLID', color: surface, opacity: 0 }];
  assistChip.strokes = [{ type: 'SOLID', color: outline }];
  assistChip.strokeWeight = 1;
  const assistLabel = figma.createText();
  assistLabel.fontName = { family: font, style: 'Medium' };
  assistLabel.fontSize = 14;
  assistLabel.characters = 'Assist';
  assistLabel.fills = [{ type: 'SOLID', color: onSurface }];
  assistChip.appendChild(assistLabel);
  chipRow.appendChild(assistChip);

  const filterChip = figma.createComponent();
  filterChip.name = 'Type=Filter, Selected=true';
  filterChip.resize(100, 32);
  filterChip.layoutMode = 'HORIZONTAL';
  filterChip.primaryAxisAlignItems = 'CENTER';
  filterChip.counterAxisAlignItems = 'CENTER';
  filterChip.paddingLeft = 16;
  filterChip.paddingRight = 16;
  filterChip.cornerRadius = radiusFull;
  filterChip.fills = [{ type: 'SOLID', color: secondaryContainer }];
  const filterLabel = figma.createText();
  filterLabel.fontName = { family: font, style: 'Medium' };
  filterLabel.fontSize = 14;
  filterLabel.characters = 'Filter';
  filterLabel.fills = [{ type: 'SOLID', color: onSecondaryContainer }];
  filterChip.appendChild(filterLabel);
  chipRow.appendChild(filterChip);

  figma.combineAsVariants([assistChip, filterChip], chipRow);
}
