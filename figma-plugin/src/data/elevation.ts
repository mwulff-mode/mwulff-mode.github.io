export interface ElevationToken {
  name: string;
  a: { y: number; blur: number; opacity: number } | null;
  b: { y: number; blur: number; opacity: number } | null;
}

export const elevationScale: ElevationToken[] = [
  { name: 'elevation/0', a: null, b: null },
  { name: 'elevation/1', a: { y: 1, blur: 6, opacity: 0.08 }, b: { y: 1, blur: 3, opacity: 0.12 } },
  { name: 'elevation/2', a: { y: 2, blur: 12, opacity: 0.08 }, b: { y: 2, blur: 6, opacity: 0.10 } },
  { name: 'elevation/3', a: { y: 4, blur: 20, opacity: 0.10 }, b: { y: 4, blur: 10, opacity: 0.12 } },
  { name: 'elevation/4', a: { y: 6, blur: 28, opacity: 0.10 }, b: { y: 6, blur: 14, opacity: 0.12 } },
  { name: 'elevation/5', a: { y: 10, blur: 40, opacity: 0.12 }, b: { y: 10, blur: 24, opacity: 0.14 } },
];
