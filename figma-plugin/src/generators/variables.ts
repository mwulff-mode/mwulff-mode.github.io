import { hexToFigmaRgb, hexToFigmaRgba } from '../utils/color';
import { primitivesA, primitivesB, semanticColors, type PrimitiveGroup } from '../data/colors';
import { spacingScale, sizingScale } from '../data/spacing';
import { radiusScale } from '../data/radius';
import { fontFamilies } from '../data/typography';

export type Direction = 'direction-a' | 'direction-b' | 'both';

interface ModeConfig {
  modeAId: string;
  modeBId: string | null;
  isBoth: boolean;
}

/** Flatten a PrimitiveGroup[] into a name→hex map */
function flattenPrimitives(groups: PrimitiveGroup[]): Map<string, string> {
  const map = new Map<string, string>();
  for (const group of groups) {
    for (const c of group.colors) {
      map.set(c.name, c.hex);
    }
  }
  return map;
}

/** Create a variable collection with appropriate modes */
function createCollection(name: string, direction: Direction): { collection: VariableCollection; config: ModeConfig } {
  const collection = figma.variables.createVariableCollection(name);

  if (direction === 'both') {
    const defaultModeId = collection.modes[0].modeId;
    collection.renameMode(defaultModeId, 'Soft Piggy Bank');
    const modeBId = collection.addMode('Smart & Clean');
    return {
      collection,
      config: { modeAId: defaultModeId, modeBId, isBoth: true },
    };
  } else if (direction === 'direction-a') {
    const defaultModeId = collection.modes[0].modeId;
    collection.renameMode(defaultModeId, 'Soft Piggy Bank');
    return {
      collection,
      config: { modeAId: defaultModeId, modeBId: null, isBoth: false },
    };
  } else {
    const defaultModeId = collection.modes[0].modeId;
    collection.renameMode(defaultModeId, 'Smart & Clean');
    return {
      collection,
      config: { modeAId: defaultModeId, modeBId: null, isBoth: false },
    };
  }
}

/** Create all color variables (primitives + semantics) */
export function createColorVariables(direction: Direction): {
  collection: VariableCollection;
  semanticVarMap: Map<string, Variable>;
} {
  const { collection, config } = createCollection('Colors', direction);
  const semanticVarMap = new Map<string, Variable>();

  const mapA = flattenPrimitives(primitivesA);
  const mapB = flattenPrimitives(primitivesB);

  // Create primitive variables
  const primitiveVarMap = new Map<string, Variable>();
  const allPrimitiveNames = new Set<string>();
  mapA.forEach(function(_v, k) { allPrimitiveNames.add(k); });
  mapB.forEach(function(_v, k) { allPrimitiveNames.add(k); });

  for (const name of allPrimitiveNames) {
    const variable = figma.variables.createVariable(name, collection, 'COLOR');
    variable.scopes = ['ALL_FILLS', 'STROKE_COLOR', 'EFFECT_COLOR'];
    primitiveVarMap.set(name, variable);

    if (config.isBoth) {
      const hexA = mapA.get(name);
      const hexB = mapB.get(name);
      if (hexA) variable.setValueForMode(config.modeAId, hexToFigmaRgb(hexA));
      if (hexB && config.modeBId) variable.setValueForMode(config.modeBId, hexToFigmaRgb(hexB));
    } else if (direction === 'direction-a') {
      const hex = mapA.get(name);
      if (hex) variable.setValueForMode(config.modeAId, hexToFigmaRgb(hex));
    } else {
      const hex = mapB.get(name);
      if (hex) variable.setValueForMode(config.modeAId, hexToFigmaRgb(hex));
    }
  }

  // Create semantic variables as aliases
  for (const token of semanticColors) {
    const variable = figma.variables.createVariable(token.name, collection, 'COLOR');
    variable.scopes = ['ALL_FILLS', 'STROKE_COLOR', 'EFFECT_COLOR'];
    semanticVarMap.set(token.name, variable);

    if (token.alphaA !== undefined || token.alphaB !== undefined) {
      if (config.isBoth) {
        const hexA = mapA.get(token.refA);
        const hexB = mapB.get(token.refB);
        if (hexA) variable.setValueForMode(config.modeAId, hexToFigmaRgba(hexA, token.alphaA ?? 1));
        if (hexB && config.modeBId) variable.setValueForMode(config.modeBId, hexToFigmaRgba(hexB, token.alphaB ?? 1));
      } else {
        const ref = direction === 'direction-a' ? token.refA : token.refB;
        const alpha = direction === 'direction-a' ? (token.alphaA ?? 1) : (token.alphaB ?? 1);
        const hex = (direction === 'direction-a' ? mapA : mapB).get(ref);
        if (hex) variable.setValueForMode(config.modeAId, hexToFigmaRgba(hex, alpha));
      }
    } else {
      if (config.isBoth) {
        const varA = primitiveVarMap.get(token.refA);
        const varB = primitiveVarMap.get(token.refB);
        if (varA) variable.setValueForMode(config.modeAId, figma.variables.createVariableAlias(varA));
        if (varB && config.modeBId) variable.setValueForMode(config.modeBId, figma.variables.createVariableAlias(varB));
      } else {
        const ref = direction === 'direction-a' ? token.refA : token.refB;
        const primitiveVar = primitiveVarMap.get(ref);
        if (primitiveVar) variable.setValueForMode(config.modeAId, figma.variables.createVariableAlias(primitiveVar));
      }
    }
  }

  return { collection, semanticVarMap };
}

/** Create spacing + sizing variables (shared, single mode) */
export function createSpacingVariables(): { collection: VariableCollection; varMap: Map<string, Variable> } {
  const collection = figma.variables.createVariableCollection('Spacing');
  const modeId = collection.modes[0].modeId;
  collection.renameMode(modeId, 'Default');
  const varMap = new Map<string, Variable>();

  for (const token of spacingScale) {
    const variable = figma.variables.createVariable(token.name, collection, 'FLOAT');
    variable.scopes = ['GAP', 'WIDTH_HEIGHT'];
    variable.setValueForMode(modeId, token.value);
    varMap.set(token.name, variable);
  }

  for (const token of sizingScale) {
    const variable = figma.variables.createVariable(token.name, collection, 'FLOAT');
    variable.scopes = ['WIDTH_HEIGHT'];
    variable.setValueForMode(modeId, token.value);
    varMap.set(token.name, variable);
  }

  return { collection, varMap };
}

/** Create radius variables (per direction) */
export function createRadiusVariables(direction: Direction): { collection: VariableCollection; varMap: Map<string, Variable> } {
  const { collection, config } = createCollection('Radius', direction);
  const varMap = new Map<string, Variable>();

  for (const token of radiusScale) {
    const variable = figma.variables.createVariable(token.name, collection, 'FLOAT');
    variable.scopes = ['CORNER_RADIUS'];
    varMap.set(token.name, variable);

    if (config.isBoth) {
      variable.setValueForMode(config.modeAId, token.valueA);
      if (config.modeBId) variable.setValueForMode(config.modeBId, token.valueB);
    } else if (direction === 'direction-a') {
      variable.setValueForMode(config.modeAId, token.valueA);
    } else {
      variable.setValueForMode(config.modeAId, token.valueB);
    }
  }

  return { collection, varMap };
}

/** Create typography string variables (font family per direction) */
export function createTypographyVariables(direction: Direction): { collection: VariableCollection } {
  const { collection, config } = createCollection('Typography', direction);

  const fontVar = figma.variables.createVariable('font/family', collection, 'STRING');
  fontVar.scopes = ['FONT_FAMILY'];

  if (config.isBoth) {
    fontVar.setValueForMode(config.modeAId, fontFamilies.directionA);
    if (config.modeBId) fontVar.setValueForMode(config.modeBId, fontFamilies.directionB);
  } else if (direction === 'direction-a') {
    fontVar.setValueForMode(config.modeAId, fontFamilies.directionA);
  } else {
    fontVar.setValueForMode(config.modeAId, fontFamilies.directionB);
  }

  return { collection };
}
