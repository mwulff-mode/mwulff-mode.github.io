export interface SpacingToken {
  name: string;
  value: number;
}

export const spacingScale: SpacingToken[] = [
  { name: 'space/0', value: 0 },
  { name: 'space/1', value: 2 },
  { name: 'space/2', value: 4 },
  { name: 'space/3', value: 8 },
  { name: 'space/4', value: 12 },
  { name: 'space/5', value: 16 },
  { name: 'space/6', value: 20 },
  { name: 'space/7', value: 24 },
  { name: 'space/8', value: 32 },
  { name: 'space/9', value: 40 },
  { name: 'space/10', value: 48 },
  { name: 'space/11', value: 64 },
  { name: 'space/12', value: 80 },
];

export interface SizingToken {
  name: string;
  value: number;
}

export const sizingScale: SizingToken[] = [
  { name: 'icon/sm', value: 20 },
  { name: 'icon/md', value: 24 },
  { name: 'icon/lg', value: 40 },
  { name: 'icon/xl', value: 48 },
  { name: 'touch-target', value: 48 },
];
