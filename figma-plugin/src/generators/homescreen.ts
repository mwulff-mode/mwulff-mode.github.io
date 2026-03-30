import { hexToFigmaRgb } from '../utils/color';
import { fontFamilies } from '../data/typography';
import type { Direction } from './variables';

// ── Helpers ───────────────────────────────────────────────────

/** Create a text node and append to parent */
function h(
  parent: FrameNode,
  chars: string,
  family: string,
  style: string,
  size: number,
  hex: string,
  opacity?: number,
): TextNode {
  const t = figma.createText();
  t.fontName = { family, style };
  t.fontSize = size;
  t.characters = chars;
  t.fills = [{ type: 'SOLID', color: hexToFigmaRgb(hex), opacity }];
  parent.appendChild(t);
  return t;
}

/** Create an auto-layout frame */
function box(
  name: string,
  direction: 'VERTICAL' | 'HORIZONTAL',
  gap: number,
  padding: number | [number, number, number, number],
  fills: Paint[],
  radius?: number,
): FrameNode {
  const f = figma.createFrame();
  f.name = name;
  f.layoutMode = direction;
  f.itemSpacing = gap;
  f.primaryAxisSizingMode = 'AUTO';
  f.counterAxisSizingMode = 'AUTO';
  f.fills = fills;
  if (radius !== undefined) f.cornerRadius = radius;
  if (typeof padding === 'number') {
    f.paddingTop = padding;
    f.paddingRight = padding;
    f.paddingBottom = padding;
    f.paddingLeft = padding;
  } else {
    f.paddingTop = padding[0];
    f.paddingRight = padding[1];
    f.paddingBottom = padding[2];
    f.paddingLeft = padding[3];
  }
  return f;
}

/** Solid fill shorthand */
function solid(hex: string, opacity?: number): SolidPaint {
  return { type: 'SOLID', color: hexToFigmaRgb(hex), opacity };
}

/** Linear gradient fill (top-to-bottom) */
function gradientTB(stops: Array<{ hex: string; pos: number }>): GradientPaint {
  return {
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [0, 1, 0],
      [-1, 0, 1],
    ],
    gradientStops: stops.map((s) => ({
      position: s.pos,
      color: { ...hexToFigmaRgb(s.hex), a: 1 },
    })),
  };
}

// ── Constants ─────────────────────────────────────────────────

const PHONE_W = 375;
const PHONE_H = 812;
const FRAME_GAP = 60;
const SIDE_PAD = 20; // horizontal padding inside phone (matches HTML 20px margin)
const CONTENT_W = PHONE_W - SIDE_PAD * 2; // 335

// ── Direction A — "Soft Piggy Bank" ───────────────────────────

function buildDirectionA(): FrameNode {
  const phone = figma.createFrame();
  phone.name = 'A — Soft Piggy Bank';
  phone.resize(PHONE_W, PHONE_H);
  phone.fills = [
    gradientTB([
      { hex: '#FAF8F5', pos: 0 },
      { hex: '#F2EDE6', pos: 1 },
    ]),
  ];
  phone.layoutMode = 'VERTICAL';
  phone.primaryAxisSizingMode = 'FIXED';
  phone.counterAxisSizingMode = 'FIXED';
  phone.itemSpacing = 0;
  phone.clipsContent = true;

  const font = fontFamilies.directionA; // Nunito

  // ── Status bar (56px top pad + 8px bottom = 64px zone) ──
  const statusBar = box('Status Bar', 'HORIZONTAL', 0, [56, 24, 8, 24], []);
  statusBar.resize(PHONE_W, 72);
  statusBar.primaryAxisSizingMode = 'FIXED';
  statusBar.counterAxisSizingMode = 'FIXED';
  statusBar.counterAxisAlignItems = 'CENTER';
  statusBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
  h(statusBar, '9:41', 'Inter', 'Semi Bold', 14, '#4A443C');
  h(statusBar, '▂▄▆█  ◐  ▐██▌', 'Inter', 'Regular', 11, '#4A443C');
  phone.appendChild(statusBar);

  // ── Greeting row ──
  const greetRow = box('Greeting', 'HORIZONTAL', 0, [12, 24, 4, 24], []);
  greetRow.resize(PHONE_W, 50);
  greetRow.primaryAxisSizingMode = 'FIXED';
  greetRow.counterAxisSizingMode = 'AUTO';
  greetRow.primaryAxisAlignItems = 'SPACE_BETWEEN';
  greetRow.counterAxisAlignItems = 'CENTER';

  const greetText = h(greetRow, 'Good morning, Lisa', font, 'Bold', 22, '#2D2A26');
  greetText.layoutGrow = 1;

  // Avatar circle with letter
  const avatar = figma.createFrame();
  avatar.name = 'Avatar';
  avatar.resize(42, 42);
  avatar.cornerRadius = 21;
  avatar.fills = [solid('#F2DCD9')];
  avatar.layoutMode = 'VERTICAL';
  avatar.primaryAxisAlignItems = 'CENTER';
  avatar.counterAxisAlignItems = 'CENTER';
  h(avatar, 'L', font, 'Bold', 16, '#A36B63');
  greetRow.appendChild(avatar);

  phone.appendChild(greetRow);

  // ── Balance card — sage green with ring ──
  const cardWrap = box('Card Wrap', 'VERTICAL', 0, [16, SIDE_PAD, 0, SIDE_PAD], []);
  cardWrap.resize(PHONE_W, 10);
  cardWrap.primaryAxisSizingMode = 'AUTO';
  cardWrap.counterAxisSizingMode = 'FIXED';

  const balanceCard = box('Balance Card', 'VERTICAL', 0, [28, 24, 24, 24], [
    gradientTB([
      { hex: '#6B9B6E', pos: 0 },
      { hex: '#5E8A60', pos: 0.5 },
      { hex: '#4D7A50', pos: 1 },
    ]),
  ], 24);
  balanceCard.resize(CONTENT_W, 10);
  balanceCard.primaryAxisSizingMode = 'AUTO';
  balanceCard.counterAxisSizingMode = 'FIXED';
  balanceCard.effects = [
    {
      type: 'DROP_SHADOW',
      color: { r: 0.37, g: 0.54, b: 0.38, a: 0.3 },
      offset: { x: 0, y: 8 },
      radius: 32,
      spread: 0,
      visible: true,
      blendMode: 'NORMAL',
    },
  ];

  // Decorative circle (top-right)
  const decoCircle1 = figma.createEllipse();
  decoCircle1.name = 'Deco 1';
  decoCircle1.resize(100, 100);
  decoCircle1.fills = [solid('#FFFFFF', 0.06)];
  decoCircle1.constraints = { horizontal: 'MAX', vertical: 'MIN' };
  decoCircle1.x = CONTENT_W - 56;
  decoCircle1.y = -20;

  // Decorative circle (bottom-left)
  const decoCircle2 = figma.createEllipse();
  decoCircle2.name = 'Deco 2';
  decoCircle2.resize(70, 70);
  decoCircle2.fills = [solid('#FFFFFF', 0.04)];
  decoCircle2.x = 20;
  decoCircle2.y = 120;

  // Ring + info horizontal layout
  const cardLayout = box('Card Layout', 'HORIZONTAL', 20, 0, []);
  cardLayout.counterAxisAlignItems = 'CENTER';

  // Ring container
  const ringSize = 110;
  const ringContainer = figma.createFrame();
  ringContainer.name = 'Ring Progress';
  ringContainer.resize(ringSize, ringSize);
  ringContainer.fills = [];
  ringContainer.clipsContent = false;

  // Track ring (full donut, faint white)
  const ringTrack = figma.createEllipse();
  ringTrack.name = 'Ring Track';
  ringTrack.resize(ringSize, ringSize);
  ringTrack.fills = [solid('#FFFFFF', 0.2)];
  ringTrack.strokes = [];
  ringTrack.arcData = {
    startingAngle: 0,
    endingAngle: Math.PI * 2,
    innerRadius: 0.87,
  };
  ringContainer.appendChild(ringTrack);

  // Fill ring (~50% donut, solid white)
  const ringFill = figma.createEllipse();
  ringFill.name = 'Ring Fill';
  ringFill.resize(ringSize, ringSize);
  ringFill.fills = [solid('#FFFFFF')];
  ringFill.strokes = [];
  ringFill.arcData = {
    startingAngle: -Math.PI / 2,
    endingAngle: Math.PI * 0.49,
    innerRadius: 0.87,
  };
  ringContainer.appendChild(ringFill);

  // Center amount text (absolute positioned)
  const amountLabel = figma.createText();
  amountLabel.fontName = { family: font, style: 'Bold' };
  amountLabel.fontSize = 26;
  amountLabel.characters = '$12.40';
  amountLabel.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  amountLabel.letterSpacing = { value: -0.5, unit: 'PIXELS' };
  amountLabel.textAlignHorizontal = 'CENTER';
  // Center in ring
  amountLabel.x = (ringSize - 85) / 2;
  amountLabel.y = (ringSize - 30) / 2;
  ringContainer.appendChild(amountLabel);

  cardLayout.appendChild(ringContainer);

  // Card info (right of ring)
  const cardInfo = box('Card Info', 'VERTICAL', 2, 0, []);
  h(cardInfo, 'Next cashout at', font, 'SemiBold', 13, '#FFFFFF', 0.65);
  h(cardInfo, '$25.00', font, 'Bold', 15, '#FFFFFF');

  // Spacer
  const spacer = figma.createFrame();
  spacer.name = 'spacer';
  spacer.resize(1, 10);
  spacer.fills = [];
  cardInfo.appendChild(spacer);

  // "+$1.25 today" badge
  const todayBadge = box('Today Badge', 'HORIZONTAL', 5, [5, 14, 5, 14], [
    solid('#FFFFFF', 0.18),
  ], 99);
  h(todayBadge, '↗ +$1.25 today', font, 'Bold', 13, '#FFFFFF');
  cardInfo.appendChild(todayBadge);

  cardLayout.appendChild(cardInfo);
  balanceCard.appendChild(cardLayout);
  cardWrap.appendChild(balanceCard);
  phone.appendChild(cardWrap);

  // ── CTA — pill with glow ──
  const ctaWrap = box('CTA Wrap', 'VERTICAL', 0, [20, SIDE_PAD, 0, SIDE_PAD], []);
  ctaWrap.resize(PHONE_W, 10);
  ctaWrap.primaryAxisSizingMode = 'AUTO';
  ctaWrap.counterAxisSizingMode = 'FIXED';

  const cta = box('CTA', 'HORIZONTAL', 0, [16, 0, 16, 0], [solid('#5E8A60')], 99);
  cta.resize(CONTENT_W, 52);
  cta.primaryAxisSizingMode = 'FIXED';
  cta.counterAxisSizingMode = 'FIXED';
  cta.primaryAxisAlignItems = 'CENTER';
  cta.counterAxisAlignItems = 'CENTER';
  cta.effects = [
    {
      type: 'DROP_SHADOW',
      color: { r: 0.37, g: 0.54, b: 0.38, a: 0.35 },
      offset: { x: 0, y: 4 },
      radius: 20,
      spread: 0,
      visible: true,
      blendMode: 'NORMAL',
    },
  ];
  h(cta, 'Start earning', font, 'Bold', 16, '#FFFFFF');
  ctaWrap.appendChild(cta);
  phone.appendChild(ctaWrap);

  // ── Section header ──
  const sectionHeader = box('Section Header', 'HORIZONTAL', 0, [28, 24, 14, 24], []);
  sectionHeader.resize(PHONE_W, 10);
  sectionHeader.primaryAxisSizingMode = 'FIXED';
  sectionHeader.counterAxisSizingMode = 'AUTO';
  sectionHeader.primaryAxisAlignItems = 'SPACE_BETWEEN';
  h(sectionHeader, 'Available now', font, 'Bold', 18, '#2D2A26');
  h(sectionHeader, 'See all', font, 'SemiBold', 13, '#5E8A60');
  phone.appendChild(sectionHeader);

  // ── Task cards ──
  const taskList = box('Task List', 'VERTICAL', 12, [0, SIDE_PAD, 0, SIDE_PAD], []);
  taskList.resize(PHONE_W, 10);
  taskList.primaryAxisSizingMode = 'AUTO';
  taskList.counterAxisSizingMode = 'FIXED';

  const tasks = [
    { title: 'Quick poll', meta: '3 min', value: '$0.40', borderColor: '#7568A0', iconBg: '#E2DCF0', iconColor: '#7568A0' },
    { title: 'Receipt scan', meta: '2 min', value: '$0.60', borderColor: '#A36B63', iconBg: '#F2DCD9', iconColor: '#A36B63' },
    { title: 'Short survey', meta: '5 min', value: '$0.75', borderColor: '#5E8A60', iconBg: '#D4E6D5', iconColor: '#5E8A60' },
  ];

  for (const task of tasks) {
    const card = box(`Task: ${task.title}`, 'HORIZONTAL', 14, [16, 16, 16, 16], [solid('#FFFFFF')], 16);
    card.resize(CONTENT_W, 10);
    card.primaryAxisSizingMode = 'FIXED';
    card.counterAxisSizingMode = 'AUTO';
    card.counterAxisAlignItems = 'CENTER';
    card.effects = [
      {
        type: 'DROP_SHADOW',
        color: { r: 0.18, g: 0.16, b: 0.15, a: 0.08 },
        offset: { x: 0, y: 2 },
        radius: 12,
        spread: 0,
        visible: true,
        blendMode: 'NORMAL',
      },
    ];
    // Colored left border via stroke
    card.strokes = [{ type: 'SOLID', color: hexToFigmaRgb(task.borderColor) }];
    card.strokeWeight = 4;
    card.strokeAlign = 'INSIDE';
    card.strokesIncludedInLayout = true;
    // Only left side
    card.strokeTopWeight = 0;
    card.strokeRightWeight = 0;
    card.strokeBottomWeight = 0;
    card.strokeLeftWeight = 4;

    // Icon
    const icon = figma.createFrame();
    icon.name = 'Icon';
    icon.resize(42, 42);
    icon.cornerRadius = 14;
    icon.fills = [solid(task.iconBg)];
    icon.layoutMode = 'VERTICAL';
    icon.primaryAxisAlignItems = 'CENTER';
    icon.counterAxisAlignItems = 'CENTER';
    // Simple placeholder glyph
    const iconGlyph = task.title === 'Quick poll' ? '💬' : task.title === 'Receipt scan' ? '📄' : '📋';
    h(icon, iconGlyph, 'Inter', 'Regular', 18, task.iconColor);
    card.appendChild(icon);

    // Task info (grows to fill)
    const info = box('Info', 'VERTICAL', 2, 0, []);
    info.layoutGrow = 1;
    h(info, task.title, font, 'Bold', 15, '#2D2A26');
    h(info, task.meta, font, 'Medium', 13, '#9E968B');
    card.appendChild(info);

    // Value
    h(card, task.value, font, 'Bold', 17, '#5E8A60');

    taskList.appendChild(card);
  }

  phone.appendChild(taskList);

  // ── Trust line ──
  const trustLine = box('Trust', 'HORIZONTAL', 6, [20, 24, 8, 24], []);
  trustLine.resize(PHONE_W, 10);
  trustLine.primaryAxisSizingMode = 'FIXED';
  trustLine.counterAxisSizingMode = 'AUTO';
  trustLine.primaryAxisAlignItems = 'CENTER';
  h(trustLine, '🛡️', 'Inter', 'Regular', 14, '#5E8A60');
  h(trustLine, 'Paid out via PayPal', font, 'SemiBold', 12, '#9E968B');
  phone.appendChild(trustLine);

  // ── Spacer to push nav down ──
  const navSpacer = figma.createFrame();
  navSpacer.name = 'Spacer';
  navSpacer.layoutGrow = 1;
  navSpacer.fills = [];
  navSpacer.resize(PHONE_W, 1);
  phone.appendChild(navSpacer);

  // ── Bottom nav ──
  const nav = box('Bottom Nav', 'HORIZONTAL', 0, [10, 8, 28, 8], [solid('#FFFFFF')]);
  nav.resize(PHONE_W, 72);
  nav.primaryAxisSizingMode = 'FIXED';
  nav.counterAxisSizingMode = 'FIXED';
  nav.primaryAxisAlignItems = 'SPACE_BETWEEN';
  nav.strokes = [{ type: 'SOLID', color: hexToFigmaRgb('#F0ECE6') }];
  nav.strokeWeight = 1;
  nav.strokeAlign = 'INSIDE';
  nav.strokeTopWeight = 1;
  nav.strokeRightWeight = 0;
  nav.strokeBottomWeight = 0;
  nav.strokeLeftWeight = 0;

  const navItems = ['Home', 'Activity', 'Rewards', 'Profile'];
  const navIcons = ['🏠', '📊', '🎁', '👤'];
  for (let i = 0; i < navItems.length; i++) {
    const label = navItems[i];
    const isActive = label === 'Home';

    const item = box(`Nav ${label}`, 'VERTICAL', 3, [6, 16, 0, 16], isActive ? [solid('#5E8A60', 0.12)] : [], isActive ? 14 : 0);
    item.counterAxisAlignItems = 'CENTER';

    h(item, navIcons[i], 'Inter', 'Regular', 20, isActive ? '#5E8A60' : '#9E968B');
    h(item, label, font, 'Bold', 10, isActive ? '#5E8A60' : '#9E968B');
    nav.appendChild(item);
  }

  phone.appendChild(nav);

  return phone;
}

// ── Direction B — "Smart & Clean" ─────────────────────────────

function buildDirectionB(): FrameNode {
  const phone = figma.createFrame();
  phone.name = 'B — Smart & Clean';
  phone.resize(PHONE_W, PHONE_H);
  phone.fills = [solid('#FAFAF9')];
  phone.layoutMode = 'VERTICAL';
  phone.primaryAxisSizingMode = 'FIXED';
  phone.counterAxisSizingMode = 'FIXED';
  phone.itemSpacing = 0;
  phone.clipsContent = true;

  const font = fontFamilies.directionB; // DM Sans

  // ── Dark teal header ──
  const header = figma.createFrame();
  header.name = 'Header';
  header.resize(PHONE_W, 340);
  header.fills = [
    gradientTB([
      { hex: '#0C3635', pos: 0 },
      { hex: '#176463', pos: 1 },
    ]),
  ];
  header.layoutMode = 'VERTICAL';
  header.primaryAxisSizingMode = 'AUTO';
  header.counterAxisSizingMode = 'FIXED';
  header.paddingTop = 56;
  header.paddingBottom = 28;
  header.paddingLeft = 24;
  header.paddingRight = 24;
  header.itemSpacing = 0;
  header.bottomLeftRadius = 24;
  header.bottomRightRadius = 24;

  // Status bar
  const statusBar = box('Status Bar', 'HORIZONTAL', 0, [0, 0, 12, 0], []);
  statusBar.resize(PHONE_W - 48, 28);
  statusBar.primaryAxisSizingMode = 'FIXED';
  statusBar.counterAxisSizingMode = 'FIXED';
  statusBar.counterAxisAlignItems = 'CENTER';
  statusBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
  h(statusBar, '9:41', 'Inter', 'Semi Bold', 14, '#FFFFFF');
  h(statusBar, '▂▄▆█  ◐  ▐██▌', 'Inter', 'Regular', 11, '#FFFFFF');
  header.appendChild(statusBar);

  // Greeting row with avatar
  const greetRow = box('Greeting', 'HORIZONTAL', 0, [4, 0, 20, 0], []);
  greetRow.resize(PHONE_W - 48, 34);
  greetRow.primaryAxisSizingMode = 'FIXED';
  greetRow.counterAxisSizingMode = 'FIXED';
  greetRow.primaryAxisAlignItems = 'SPACE_BETWEEN';
  greetRow.counterAxisAlignItems = 'CENTER';

  h(greetRow, 'Good morning, Lisa', font, 'Medium', 14, '#FFFFFF', 0.6);

  // Avatar
  const avatar = figma.createFrame();
  avatar.name = 'Avatar';
  avatar.resize(34, 34);
  avatar.cornerRadius = 17;
  avatar.fills = [solid('#FFFFFF', 0.12)];
  avatar.layoutMode = 'VERTICAL';
  avatar.primaryAxisAlignItems = 'CENTER';
  avatar.counterAxisAlignItems = 'CENTER';
  h(avatar, 'L', font, 'Bold', 13, '#FFFFFF', 0.8);
  greetRow.appendChild(avatar);
  header.appendChild(greetRow);

  // Balance — big white
  const balanceText = h(header, '$12.40', font, 'Bold', 52, '#FFFFFF');
  balanceText.letterSpacing = { value: -2, unit: 'PIXELS' };
  balanceText.lineHeight = { value: 56, unit: 'PIXELS' };

  // Today earnings + sparkline row
  const balanceRow = box('Balance Row', 'HORIZONTAL', 0, [10, 0, 0, 0], []);
  balanceRow.resize(PHONE_W - 48, 28);
  balanceRow.primaryAxisSizingMode = 'FIXED';
  balanceRow.counterAxisSizingMode = 'FIXED';
  balanceRow.primaryAxisAlignItems = 'SPACE_BETWEEN';
  balanceRow.counterAxisAlignItems = 'CENTER';

  const todayInfo = box('Today', 'HORIZONTAL', 5, 0, []);
  todayInfo.counterAxisAlignItems = 'CENTER';
  h(todayInfo, '↗', 'Inter', 'Regular', 12, '#82C8C7');
  h(todayInfo, '+$1.25 today', font, 'SemiBold', 14, '#82C8C7');
  balanceRow.appendChild(todayInfo);

  // Sparkline placeholder (small rising chart)
  const sparkline = figma.createFrame();
  sparkline.name = 'Sparkline';
  sparkline.resize(80, 28);
  sparkline.fills = [];
  // Draw sparkline as a series of small rectangles approximating the line
  const sparkPoints = [24, 20, 22, 14, 16, 8, 10, 4];
  for (let i = 0; i < sparkPoints.length; i++) {
    const dot = figma.createEllipse();
    dot.name = `pt${i}`;
    dot.resize(3, 3);
    dot.fills = [solid('#82C8C7')];
    dot.x = i * 11;
    dot.y = sparkPoints[i];
    sparkline.appendChild(dot);
  }
  // Connecting lines (thin rectangles between points)
  for (let i = 0; i < sparkPoints.length - 1; i++) {
    const line = figma.createFrame();
    line.name = `line${i}`;
    const x1 = i * 11 + 1.5;
    const y1 = sparkPoints[i] + 1.5;
    const x2 = (i + 1) * 11 + 1.5;
    const y2 = sparkPoints[i + 1] + 1.5;
    const dx = x2 - x1;
    const dy = y2 - y1;
    const len = Math.sqrt(dx * dx + dy * dy);
    line.resize(len, 2);
    line.fills = [solid('#82C8C7')];
    line.cornerRadius = 1;
    line.rotation = -Math.atan2(dy, dx) * (180 / Math.PI);
    line.x = x1;
    line.y = y1;
    sparkline.appendChild(line);
  }
  // End dot (larger)
  const endDot = figma.createEllipse();
  endDot.name = 'End';
  endDot.resize(6, 6);
  endDot.fills = [solid('#82C8C7')];
  endDot.x = 7 * 11 - 1.5;
  endDot.y = sparkPoints[7] - 0.5;
  sparkline.appendChild(endDot);

  balanceRow.appendChild(sparkline);
  header.appendChild(balanceRow);

  // Progress section
  const progressWrap = box('Progress', 'VERTICAL', 8, [20, 0, 0, 0], []);
  progressWrap.resize(PHONE_W - 48, 10);
  progressWrap.primaryAxisSizingMode = 'AUTO';
  progressWrap.counterAxisSizingMode = 'FIXED';

  const progressHeader = box('Progress Header', 'HORIZONTAL', 0, 0, []);
  progressHeader.resize(PHONE_W - 48, 16);
  progressHeader.primaryAxisSizingMode = 'FIXED';
  progressHeader.counterAxisSizingMode = 'FIXED';
  progressHeader.primaryAxisAlignItems = 'SPACE_BETWEEN';
  h(progressHeader, 'Next cashout', font, 'Medium', 12, '#FFFFFF', 0.5);
  h(progressHeader, '$12.40 / $25.00', font, 'SemiBold', 12, '#FFFFFF', 0.8);
  progressWrap.appendChild(progressHeader);

  // Progress bar (thin, 4px)
  const progressTrack = figma.createFrame();
  progressTrack.name = 'Progress Track';
  progressTrack.resize(PHONE_W - 48, 4);
  progressTrack.fills = [solid('#FFFFFF', 0.15)];
  progressTrack.cornerRadius = 2;
  progressTrack.clipsContent = true;

  const progressFill = figma.createFrame();
  progressFill.name = 'Progress Fill';
  progressFill.resize(Math.round((PHONE_W - 48) * 0.496), 4);
  progressFill.fills = [solid('#82C8C7')];
  progressFill.cornerRadius = 2;
  progressTrack.appendChild(progressFill);

  progressWrap.appendChild(progressTrack);
  header.appendChild(progressWrap);
  phone.appendChild(header);

  // ── White content area ──
  const content = box('Content', 'VERTICAL', 0, 0, []);
  content.layoutGrow = 1;
  content.resize(PHONE_W, 100);
  content.primaryAxisSizingMode = 'FIXED';
  content.counterAxisSizingMode = 'FIXED';

  // ── CTA — flat, 8px radius ──
  const ctaWrap = box('CTA Wrap', 'VERTICAL', 0, [20, SIDE_PAD, 0, SIDE_PAD], []);
  ctaWrap.resize(PHONE_W, 10);
  ctaWrap.primaryAxisSizingMode = 'AUTO';
  ctaWrap.counterAxisSizingMode = 'FIXED';

  const cta = box('CTA', 'HORIZONTAL', 0, [14, 0, 14, 0], [solid('#1A6B6A')], 8);
  cta.resize(CONTENT_W, 48);
  cta.primaryAxisSizingMode = 'FIXED';
  cta.counterAxisSizingMode = 'FIXED';
  cta.primaryAxisAlignItems = 'CENTER';
  cta.counterAxisAlignItems = 'CENTER';
  const ctaText = h(cta, 'Start earning', font, 'Bold', 14, '#FFFFFF');
  ctaText.letterSpacing = { value: 0.3, unit: 'PIXELS' };
  ctaWrap.appendChild(cta);
  content.appendChild(ctaWrap);

  // ── Section header — uppercase ──
  const sectionHeader = box('Section Header', 'HORIZONTAL', 0, [24, 24, 8, 24], []);
  sectionHeader.resize(PHONE_W, 10);
  sectionHeader.primaryAxisSizingMode = 'FIXED';
  sectionHeader.counterAxisSizingMode = 'AUTO';
  sectionHeader.primaryAxisAlignItems = 'SPACE_BETWEEN';
  const sectionTitle = h(sectionHeader, 'AVAILABLE NOW', font, 'Bold', 11, '#97978F');
  sectionTitle.letterSpacing = { value: 1, unit: 'PIXELS' };
  h(sectionHeader, 'See all', font, 'SemiBold', 12, '#1A6B6A');
  content.appendChild(sectionHeader);

  // ── Task rows — compact, dividers ──
  const taskList = box('Task List', 'VERTICAL', 0, [0, 24, 0, 24], []);
  taskList.resize(PHONE_W, 10);
  taskList.primaryAxisSizingMode = 'AUTO';
  taskList.counterAxisSizingMode = 'FIXED';

  const tasks = [
    { title: 'Quick poll', meta: '3 min', value: '$0.40' },
    { title: 'Receipt scan', meta: '2 min', value: '$0.60' },
    { title: 'Short survey', meta: '5 min', value: '$0.75' },
  ];

  tasks.forEach((task, i) => {
    const row = box(`Task: ${task.title}`, 'HORIZONTAL', 12, [13, 0, 13, 0], []);
    row.resize(PHONE_W - 48, 10);
    row.primaryAxisSizingMode = 'FIXED';
    row.counterAxisSizingMode = 'AUTO';
    row.counterAxisAlignItems = 'CENTER';

    // Icon
    const icon = figma.createFrame();
    icon.name = 'Icon';
    icon.resize(32, 32);
    icon.cornerRadius = 6;
    icon.fills = [solid('#EFF8F8')];
    icon.layoutMode = 'VERTICAL';
    icon.primaryAxisAlignItems = 'CENTER';
    icon.counterAxisAlignItems = 'CENTER';
    const iconGlyph = task.title === 'Quick poll' ? '💬' : task.title === 'Receipt scan' ? '📄' : '📋';
    h(icon, iconGlyph, 'Inter', 'Regular', 14, '#1A6B6A');
    row.appendChild(icon);

    // Info (grows)
    const info = box('Info', 'VERTICAL', 2, 0, []);
    info.layoutGrow = 1;
    h(info, task.title, font, 'SemiBold', 14, '#1C1C1B');
    h(info, task.meta, font, 'Medium', 12, '#97978F');
    row.appendChild(info);

    // Value
    h(row, task.value, font, 'Bold', 14, '#1A6B6A');

    taskList.appendChild(row);

    // Divider
    if (i < tasks.length - 1) {
      const divider = figma.createFrame();
      divider.name = 'Divider';
      divider.resize(PHONE_W - 48, 1);
      divider.fills = [solid('#EEEEEB')];
      taskList.appendChild(divider);
    }
  });

  content.appendChild(taskList);

  // ── Trust line ──
  const trustLine = box('Trust', 'HORIZONTAL', 6, [16, 24, 8, 24], []);
  trustLine.resize(PHONE_W, 10);
  trustLine.primaryAxisSizingMode = 'FIXED';
  trustLine.counterAxisSizingMode = 'AUTO';
  trustLine.primaryAxisAlignItems = 'CENTER';
  h(trustLine, '🛡️', 'Inter', 'Regular', 13, '#1A6B6A');
  h(trustLine, 'Paid out via PayPal', font, 'Medium', 12, '#97978F');
  content.appendChild(trustLine);

  phone.appendChild(content);

  // ── Spacer ──
  const navSpacer = figma.createFrame();
  navSpacer.name = 'Spacer';
  navSpacer.layoutGrow = 1;
  navSpacer.fills = [];
  navSpacer.resize(PHONE_W, 1);
  phone.appendChild(navSpacer);

  // ── Bottom nav ──
  const nav = box('Bottom Nav', 'HORIZONTAL', 0, [10, 8, 28, 8], [solid('#FFFFFF')]);
  nav.resize(PHONE_W, 72);
  nav.primaryAxisSizingMode = 'FIXED';
  nav.counterAxisSizingMode = 'FIXED';
  nav.primaryAxisAlignItems = 'SPACE_BETWEEN';
  nav.strokes = [{ type: 'SOLID', color: hexToFigmaRgb('#EEEEEB') }];
  nav.strokeWeight = 1;
  nav.strokeAlign = 'INSIDE';
  nav.strokeTopWeight = 1;
  nav.strokeRightWeight = 0;
  nav.strokeBottomWeight = 0;
  nav.strokeLeftWeight = 0;

  const navItems = ['Home', 'Activity', 'Rewards', 'Profile'];
  const navIcons = ['🏠', '📊', '🎁', '👤'];
  for (let i = 0; i < navItems.length; i++) {
    const label = navItems[i];
    const isActive = label === 'Home';

    const item = box(`Nav ${label}`, 'VERTICAL', 3, [6, 16, 0, 16], []);
    item.counterAxisAlignItems = 'CENTER';

    h(item, navIcons[i], 'Inter', 'Regular', 20, isActive ? '#1A6B6A' : '#BDBDB8');
    h(item, label, font, 'SemiBold', 10, isActive ? '#1A6B6A' : '#BDBDB8');

    // Active dot
    if (isActive) {
      const dot = figma.createEllipse();
      dot.name = 'Active Dot';
      dot.resize(4, 4);
      dot.fills = [solid('#1A6B6A')];
      item.appendChild(dot);
    }

    nav.appendChild(item);
  }

  phone.appendChild(nav);

  return phone;
}

// ── Main export ───────────────────────────────────────────────

export function createHomeScreenPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '📱 Home Screen A/B';

  const wrapper = figma.createFrame();
  wrapper.name = 'Home Screen Concepts';
  wrapper.layoutMode = 'HORIZONTAL';
  wrapper.itemSpacing = FRAME_GAP;
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  wrapper.fills = [];
  wrapper.paddingTop = 40;
  wrapper.paddingLeft = 40;
  wrapper.paddingRight = 40;
  wrapper.paddingBottom = 40;

  // Labels above each phone
  const colA = box('Direction A', 'VERTICAL', 16, 0, []);
  h(colA, 'A — Soft Piggy Bank', 'Inter', 'Bold', 18, '#2D2A26');
  h(colA, '"This feels warm and friendly"', 'Inter', 'Regular', 13, '#7A7268');
  if (direction === 'direction-a' || direction === 'both') {
    colA.appendChild(buildDirectionA());
  }
  wrapper.appendChild(colA);

  const colB = box('Direction B', 'VERTICAL', 16, 0, []);
  h(colB, 'B — Smart & Clean', 'Inter', 'Bold', 18, '#1C1C1B');
  h(colB, '"This feels smart and professional"', 'Inter', 'Regular', 13, '#717169');
  if (direction === 'direction-b' || direction === 'both') {
    colB.appendChild(buildDirectionB());
  }
  wrapper.appendChild(colB);

  page.appendChild(wrapper);
}
