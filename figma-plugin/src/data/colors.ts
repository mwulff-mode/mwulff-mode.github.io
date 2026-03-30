export interface PrimitiveColor {
  name: string;
  hex: string;
}

export interface PrimitiveGroup {
  groupName: string;
  colors: PrimitiveColor[];
}

export interface SemanticColor {
  name: string;
  refA: string;
  refB: string;
  alphaA?: number;
  alphaB?: number;
}

export const primitivesA: PrimitiveGroup[] = [
  {
    groupName: 'sage',
    colors: [
      { name: 'sage/50', hex: '#F0F5F0' },
      { name: 'sage/100', hex: '#D4E6D5' },
      { name: 'sage/200', hex: '#B5D4B7' },
      { name: 'sage/400', hex: '#8BAB8D' },
      { name: 'sage/600', hex: '#5E8A60' },
      { name: 'sage/800', hex: '#3D6640' },
      { name: 'sage/900', hex: '#2A4A2D' },
    ],
  },
  {
    groupName: 'blush',
    colors: [
      { name: 'blush/50', hex: '#FBF2F1' },
      { name: 'blush/100', hex: '#F2DCD9' },
      { name: 'blush/200', hex: '#E5BCB7' },
      { name: 'blush/400', hex: '#C4918A' },
      { name: 'blush/600', hex: '#A36B63' },
      { name: 'blush/800', hex: '#7D4A43' },
    ],
  },
  {
    groupName: 'lavender',
    colors: [
      { name: 'lavender/50', hex: '#F3F0F8' },
      { name: 'lavender/100', hex: '#E2DCF0' },
      { name: 'lavender/400', hex: '#9B8EC0' },
      { name: 'lavender/600', hex: '#7568A0' },
    ],
  },
  {
    groupName: 'neutral',
    colors: [
      { name: 'neutral/0', hex: '#FFFFFF' },
      { name: 'neutral/50', hex: '#FAF8F5' },
      { name: 'neutral/100', hex: '#F0ECE6' },
      { name: 'neutral/200', hex: '#E0DAD2' },
      { name: 'neutral/300', hex: '#C5BDB3' },
      { name: 'neutral/400', hex: '#9E968B' },
      { name: 'neutral/500', hex: '#7A7268' },
      { name: 'neutral/700', hex: '#4A443C' },
      { name: 'neutral/900', hex: '#2D2A26' },
    ],
  },
  {
    groupName: 'status',
    colors: [
      { name: 'error', hex: '#C75D4A' },
      { name: 'success', hex: '#6B9E6F' },
      { name: 'warning', hex: '#D4A643' },
    ],
  },
];

export const primitivesB: PrimitiveGroup[] = [
  {
    groupName: 'teal',
    colors: [
      { name: 'teal/50', hex: '#EFF8F8' },
      { name: 'teal/100', hex: '#B8E0DF' },
      { name: 'teal/200', hex: '#82C8C7' },
      { name: 'teal/400', hex: '#3D9E9D' },
      { name: 'teal/600', hex: '#1A6B6A' },
      { name: 'teal/800', hex: '#0F4847' },
      { name: 'teal/900', hex: '#083332' },
    ],
  },
  {
    groupName: 'amber',
    colors: [
      { name: 'amber/50', hex: '#FDF8EE' },
      { name: 'amber/100', hex: '#F5E6C8' },
      { name: 'amber/200', hex: '#EBCF96' },
      { name: 'amber/400', hex: '#D4A643' },
      { name: 'amber/600', hex: '#B8860B' },
      { name: 'amber/800', hex: '#8A6408' },
    ],
  },
  {
    groupName: 'slate',
    colors: [
      { name: 'slate/50', hex: '#F2F4F7' },
      { name: 'slate/100', hex: '#D5DCE6' },
      { name: 'slate/400', hex: '#5B6F8A' },
      { name: 'slate/600', hex: '#3E5170' },
    ],
  },
  {
    groupName: 'neutral',
    colors: [
      { name: 'neutral/0', hex: '#FFFFFF' },
      { name: 'neutral/50', hex: '#FAFAF9' },
      { name: 'neutral/100', hex: '#F0F0EE' },
      { name: 'neutral/200', hex: '#DDDDD9' },
      { name: 'neutral/300', hex: '#BDBDB8' },
      { name: 'neutral/400', hex: '#97978F' },
      { name: 'neutral/500', hex: '#717169' },
      { name: 'neutral/700', hex: '#44443E' },
      { name: 'neutral/900', hex: '#1C1C1B' },
    ],
  },
  {
    groupName: 'status',
    colors: [
      { name: 'error', hex: '#C4453A' },
      { name: 'success', hex: '#3D8B7A' },
      { name: 'warning', hex: '#D4A643' },
    ],
  },
];

export const semanticColors: SemanticColor[] = [
  { name: 'color/primary', refA: 'sage/600', refB: 'teal/600' },
  { name: 'color/on-primary', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/primary-container', refA: 'sage/100', refB: 'teal/100' },
  { name: 'color/on-primary-container', refA: 'sage/900', refB: 'teal/900' },
  { name: 'color/secondary', refA: 'blush/600', refB: 'amber/600' },
  { name: 'color/on-secondary', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/secondary-container', refA: 'blush/100', refB: 'amber/100' },
  { name: 'color/on-secondary-container', refA: 'blush/800', refB: 'amber/800' },
  { name: 'color/tertiary', refA: 'lavender/600', refB: 'slate/600' },
  { name: 'color/on-tertiary', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/tertiary-container', refA: 'lavender/100', refB: 'slate/100' },
  { name: 'color/on-tertiary-container', refA: 'lavender/600', refB: 'slate/600' },
  { name: 'color/error', refA: 'error', refB: 'error' },
  { name: 'color/on-error', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/success', refA: 'success', refB: 'success' },
  { name: 'color/warning', refA: 'warning', refB: 'warning' },
  { name: 'color/surface', refA: 'neutral/50', refB: 'neutral/50' },
  { name: 'color/on-surface', refA: 'neutral/900', refB: 'neutral/900' },
  { name: 'color/on-surface-variant', refA: 'neutral/500', refB: 'neutral/500' },
  { name: 'color/surface-container-lowest', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/surface-container-low', refA: 'neutral/50', refB: 'neutral/50' },
  { name: 'color/surface-container', refA: 'neutral/100', refB: 'neutral/100' },
  { name: 'color/surface-container-high', refA: 'neutral/200', refB: 'neutral/200' },
  { name: 'color/outline', refA: 'neutral/300', refB: 'neutral/300' },
  { name: 'color/outline-variant', refA: 'neutral/200', refB: 'neutral/200' },
  { name: 'color/scrim', refA: 'neutral/900', refB: 'neutral/900', alphaA: 0.5, alphaB: 0.5 },
];
