export interface RadiusToken {
  name: string;
  valueA: number;
  valueB: number;
}

export const radiusScale: RadiusToken[] = [
  { name: 'radius/none', valueA: 0, valueB: 0 },
  { name: 'radius/xs', valueA: 8, valueB: 4 },
  { name: 'radius/sm', valueA: 12, valueB: 8 },
  { name: 'radius/md', valueA: 16, valueB: 12 },
  { name: 'radius/lg', valueA: 24, valueB: 16 },
  { name: 'radius/xl', valueA: 32, valueB: 24 },
  { name: 'radius/full', valueA: 9999, valueB: 9999 },
];
