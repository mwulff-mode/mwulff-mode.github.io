import { primitivesA, primitivesB, semanticColors, type PrimitiveGroup } from '../data/colors';
import { typeScale, fontFamilies } from '../data/typography';
import { spacingScale, sizingScale } from '../data/spacing';
import { elevationScale } from '../data/elevation';
import { hexToFigmaRgb } from '../utils/color';
import type { Direction } from './variables';

const PAGE_PADDING = 80;
const SECTION_GAP = 60;

function getDirectionLabel(direction: Direction): string {
  if (direction === 'direction-a') return 'Soft Piggy Bank';
  if (direction === 'direction-b') return 'Smart & Clean';
  return 'Both Directions';
}

function createSectionTitle(text: string, parent: FrameNode | PageNode): TextNode {
  const node = figma.createText();
  node.fontName = { family: 'Inter', style: 'Bold' };
  node.fontSize = 24;
  node.characters = text;
  node.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.1 } }];
  parent.appendChild(node);
  return node;
}

function createLabel(text: string, parent: FrameNode): TextNode {
  const node = figma.createText();
  node.fontName = { family: 'Inter', style: 'Regular' };
  node.fontSize = 11;
  node.characters = text;
  node.fills = [{ type: 'SOLID', color: { r: 0.4, g: 0.4, b: 0.4 } }];
  parent.appendChild(node);
  return node;
}

function createAutoLayoutFrame(name: string, direction: 'VERTICAL' | 'HORIZONTAL', gap: number): FrameNode {
  const frame = figma.createFrame();
  frame.name = name;
  frame.layoutMode = direction;
  frame.itemSpacing = gap;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [];
  return frame;
}

function createColorSwatch(name: string, hex: string, parent: FrameNode): void {
  const wrapper = createAutoLayoutFrame(name, 'VERTICAL', 4);

  const swatch = figma.createRectangle();
  swatch.name = name;
  swatch.resize(80, 80);
  swatch.cornerRadius = 8;
  swatch.fills = [{ type: 'SOLID', color: hexToFigmaRgb(hex) }];
  swatch.strokes = [{ type: 'SOLID', color: { r: 0.9, g: 0.9, b: 0.9 } }];
  swatch.strokeWeight = 1;
  wrapper.appendChild(swatch);

  const nameLabel = figma.createText();
  nameLabel.fontName = { family: 'Inter', style: 'Medium' };
  nameLabel.fontSize = 10;
  nameLabel.characters = name;
  nameLabel.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.2, b: 0.2 } }];
  wrapper.appendChild(nameLabel);

  const hexLabel = figma.createText();
  hexLabel.fontName = { family: 'Inter', style: 'Regular' };
  hexLabel.fontSize = 10;
  hexLabel.characters = hex;
  hexLabel.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
  wrapper.appendChild(hexLabel);

  parent.appendChild(wrapper);
}

export function createCoverPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '📋 Cover';

  const frame = figma.createFrame();
  frame.name = 'Cover';
  frame.resize(1920, 1080);
  frame.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.97, b: 0.95 } }];
  frame.layoutMode = 'VERTICAL';
  frame.primaryAxisAlignItems = 'CENTER';
  frame.counterAxisAlignItems = 'CENTER';
  frame.itemSpacing = 16;
  page.appendChild(frame);

  const title = figma.createText();
  title.fontName = { family: 'Inter', style: 'Bold' };
  title.fontSize = 48;
  title.characters = '[APP_NAME] Design System';
  title.fills = [{ type: 'SOLID', color: { r: 0.15, g: 0.15, b: 0.15 } }];
  frame.appendChild(title);

  const subtitle = figma.createText();
  subtitle.fontName = { family: 'Inter', style: 'Regular' };
  subtitle.fontSize = 20;
  subtitle.characters = `Direction: ${getDirectionLabel(direction)}`;
  subtitle.fills = [{ type: 'SOLID', color: { r: 0.4, g: 0.4, b: 0.4 } }];
  frame.appendChild(subtitle);

  const date = figma.createText();
  date.fontName = { family: 'Inter', style: 'Regular' };
  date.fontSize = 14;
  date.characters = `Generated: ${new Date().toISOString().split('T')[0]}`;
  date.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
  frame.appendChild(date);
}

function createColorGroupRow(group: PrimitiveGroup, parent: FrameNode): void {
  const groupTitle = figma.createText();
  groupTitle.fontName = { family: 'Inter', style: 'Semi Bold' };
  groupTitle.fontSize = 14;
  groupTitle.characters = group.groupName.toUpperCase();
  groupTitle.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  parent.appendChild(groupTitle);

  const row = createAutoLayoutFrame(group.groupName, 'HORIZONTAL', 12);
  for (const color of group.colors) {
    createColorSwatch(color.name, color.hex, row);
  }
  parent.appendChild(row);
}

export function createColorsPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🎨 Colors';

  const container = createAutoLayoutFrame('Colors', 'VERTICAL', SECTION_GAP);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  if (direction === 'direction-a' || direction === 'both') {
    createSectionTitle('Primitives — Soft Piggy Bank', container);
    for (const group of primitivesA) {
      createColorGroupRow(group, container);
    }
  }

  if (direction === 'direction-b' || direction === 'both') {
    createSectionTitle('Primitives — Smart & Clean', container);
    for (const group of primitivesB) {
      createColorGroupRow(group, container);
    }
  }

  createSectionTitle('Semantic Tokens', container);
  const semanticNote = figma.createText();
  semanticNote.fontName = { family: 'Inter', style: 'Regular' };
  semanticNote.fontSize = 12;
  semanticNote.characters = 'These tokens reference primitives and switch automatically when you change the variable mode.';
  semanticNote.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
  container.appendChild(semanticNote);

  const semanticRow = createAutoLayoutFrame('semantic-tokens', 'HORIZONTAL', 12);
  semanticRow.layoutWrap = 'WRAP';
  semanticRow.counterAxisSpacing = 12;
  semanticRow.resize(1200, 100);
  semanticRow.primaryAxisSizingMode = 'FIXED';
  semanticRow.counterAxisSizingMode = 'AUTO';

  const resolveMap = direction === 'direction-b'
    ? new Map(primitivesB.flatMap(g => g.colors.map(c => [c.name, c.hex] as [string, string])))
    : new Map(primitivesA.flatMap(g => g.colors.map(c => [c.name, c.hex] as [string, string])));

  for (const token of semanticColors) {
    const ref = direction === 'direction-b' ? token.refB : token.refA;
    const hex = resolveMap.get(ref) ?? '#CCCCCC';
    createColorSwatch(token.name, hex, semanticRow);
  }
  container.appendChild(semanticRow);
}

export function createTypographyPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🔤 Typography';

  const container = createAutoLayoutFrame('Typography', 'VERTICAL', 32);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  const family = direction === 'direction-b' ? fontFamilies.directionB : fontFamilies.directionA;
  createSectionTitle(`Type Scale — ${family}`, container);

  for (const token of typeScale) {
    const row = createAutoLayoutFrame(token.name, 'VERTICAL', 4);

    const meta = figma.createText();
    meta.fontName = { family: 'Inter', style: 'Medium' };
    meta.fontSize = 11;
    meta.characters = `${token.name}  |  ${token.size}/${token.lineHeight}  |  ${token.weight}  |  ls: ${token.letterSpacing}`;
    meta.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
    row.appendChild(meta);

    const sample = figma.createText();
    sample.fontName = { family, style: token.weight };
    sample.fontSize = token.size;
    sample.lineHeight = { value: token.lineHeight, unit: 'PIXELS' };
    sample.letterSpacing = { value: token.letterSpacing, unit: 'PIXELS' };
    sample.characters = 'The quick brown fox jumps over the lazy dog';
    sample.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.1 } }];
    row.appendChild(sample);

    container.appendChild(row);
  }
}

export function createSpacingPage(): void {
  const page = figma.createPage();
  page.name = '📏 Spacing & Sizing';

  const container = createAutoLayoutFrame('Spacing', 'VERTICAL', SECTION_GAP);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  createSectionTitle('Spacing Scale (8px grid)', container);

  for (const token of spacingScale) {
    if (token.value === 0) continue;

    const row = createAutoLayoutFrame(token.name, 'HORIZONTAL', 12);
    row.counterAxisAlignItems = 'CENTER';

    const label = figma.createText();
    label.fontName = { family: 'Inter', style: 'Medium' };
    label.fontSize = 12;
    label.characters = `${token.name}  (${token.value}px)`;
    label.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
    label.resize(160, label.height);
    row.appendChild(label);

    const bar = figma.createRectangle();
    bar.name = `${token.value}px`;
    bar.resize(token.value, 24);
    bar.cornerRadius = 4;
    bar.fills = [{ type: 'SOLID', color: { r: 0.35, g: 0.55, b: 0.95 } }];
    row.appendChild(bar);

    container.appendChild(row);
  }

  createSectionTitle('Icon Sizes', container);
  const iconRow = createAutoLayoutFrame('icons', 'HORIZONTAL', 24);
  iconRow.counterAxisAlignItems = 'MAX';

  for (const token of sizingScale) {
    const wrapper = createAutoLayoutFrame(token.name, 'VERTICAL', 4);
    wrapper.counterAxisAlignItems = 'CENTER';

    const rect = figma.createRectangle();
    rect.name = token.name;
    rect.resize(token.value, token.value);
    rect.cornerRadius = 4;
    rect.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
    wrapper.appendChild(rect);

    createLabel(`${token.name} (${token.value})`, wrapper);
    iconRow.appendChild(wrapper);
  }
  container.appendChild(iconRow);
}

export function createElevationPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🔲 Elevation';

  const container = createAutoLayoutFrame('Elevation', 'VERTICAL', SECTION_GAP);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  createSectionTitle('Elevation Levels', container);

  const row = createAutoLayoutFrame('levels', 'HORIZONTAL', 32);

  for (const token of elevationScale) {
    const shadow = direction === 'direction-b' ? token.b : token.a;
    const card = figma.createFrame();
    card.name = token.name;
    card.resize(160, 160);
    card.cornerRadius = 12;
    card.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    card.layoutMode = 'VERTICAL';
    card.primaryAxisAlignItems = 'CENTER';
    card.counterAxisAlignItems = 'CENTER';
    card.itemSpacing = 8;

    if (shadow) {
      card.effects = [
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

    const nameText = figma.createText();
    nameText.fontName = { family: 'Inter', style: 'Semi Bold' };
    nameText.fontSize = 14;
    nameText.characters = token.name;
    nameText.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.2, b: 0.2 } }];
    card.appendChild(nameText);

    if (shadow) {
      const detailText = figma.createText();
      detailText.fontName = { family: 'Inter', style: 'Regular' };
      detailText.fontSize = 10;
      detailText.characters = `y:${shadow.y} blur:${shadow.blur}\nopacity:${(shadow.opacity * 100).toFixed(0)}%`;
      detailText.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
      card.appendChild(detailText);
    }

    row.appendChild(card);
  }

  container.appendChild(row);
}

export function createScreenTemplatesPage(): void {
  const page = figma.createPage();
  page.name = '📱 Screen Templates';

  const screenNames = ['Home', 'Task Detail', 'Earnings'];
  let xOffset = 0;

  for (const name of screenNames) {
    const frame = figma.createFrame();
    frame.name = name;
    frame.resize(393, 852);
    frame.x = xOffset;
    frame.y = 0;
    frame.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];

    frame.layoutGrids = [
      {
        pattern: 'COLUMNS',
        alignment: 'STRETCH',
        count: 4,
        gutterSize: 16,
        offset: 16,
        visible: true,
        color: { r: 1, g: 0, b: 0, a: 0.05 },
      },
    ];

    page.appendChild(frame);
    xOffset += 393 + 40;
  }
}
