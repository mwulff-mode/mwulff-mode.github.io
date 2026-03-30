/** Convert hex string to Figma RGBA (0-1 range) */
export function hexToFigmaRgb(hex: string): RGB {
  const h = hex.replace('#', '');
  return {
    r: parseInt(h.substring(0, 2), 16) / 255,
    g: parseInt(h.substring(2, 4), 16) / 255,
    b: parseInt(h.substring(4, 6), 16) / 255,
  };
}

/** Convert hex + alpha to Figma RGBA */
export function hexToFigmaRgba(hex: string, alpha: number): RGBA {
  const rgb = hexToFigmaRgb(hex);
  return { r: rgb.r, g: rgb.g, b: rgb.b, a: alpha };
}
