export interface TypeToken {
  name: string;
  size: number;
  weight: 'Regular' | 'Medium' | 'SemiBold' | 'Bold';
  lineHeight: number;
  letterSpacing: number;
}

export const fontFamilies = {
  directionA: 'Nunito',
  directionB: 'DM Sans',
};

export const fontWeightsToLoad = ['Regular', 'Medium', 'SemiBold', 'Bold'] as const;

export const typeScale: TypeToken[] = [
  { name: 'display/large', size: 57, weight: 'Regular', lineHeight: 64, letterSpacing: -0.25 },
  { name: 'display/medium', size: 45, weight: 'Regular', lineHeight: 52, letterSpacing: 0 },
  { name: 'display/small', size: 36, weight: 'Regular', lineHeight: 44, letterSpacing: 0 },
  { name: 'headline/large', size: 32, weight: 'Regular', lineHeight: 40, letterSpacing: 0 },
  { name: 'headline/medium', size: 28, weight: 'Regular', lineHeight: 36, letterSpacing: 0 },
  { name: 'headline/small', size: 24, weight: 'Regular', lineHeight: 32, letterSpacing: 0 },
  { name: 'title/large', size: 22, weight: 'Regular', lineHeight: 28, letterSpacing: 0 },
  { name: 'title/medium', size: 16, weight: 'Medium', lineHeight: 24, letterSpacing: 0.15 },
  { name: 'title/small', size: 14, weight: 'Medium', lineHeight: 20, letterSpacing: 0.1 },
  { name: 'body/large', size: 16, weight: 'Regular', lineHeight: 24, letterSpacing: 0.5 },
  { name: 'body/medium', size: 14, weight: 'Regular', lineHeight: 20, letterSpacing: 0.25 },
  { name: 'body/small', size: 12, weight: 'Regular', lineHeight: 16, letterSpacing: 0.4 },
  { name: 'label/large', size: 14, weight: 'Medium', lineHeight: 20, letterSpacing: 0.1 },
  { name: 'label/medium', size: 12, weight: 'Medium', lineHeight: 16, letterSpacing: 0.5 },
  { name: 'label/small', size: 11, weight: 'Medium', lineHeight: 16, letterSpacing: 0.5 },
];
