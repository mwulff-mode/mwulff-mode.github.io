import { createColorVariables, createSpacingVariables, createRadiusVariables, createTypographyVariables, type Direction } from './generators/variables';
import { loadFonts, createTextStyles, createEffectStyles, createGridStyle } from './generators/styles';
import { createCoverPage, createColorsPage, createTypographyPage, createSpacingPage, createElevationPage, createScreenTemplatesPage } from './generators/pages';
import { createComponentsPage } from './generators/components';
import { createHomeScreenPage } from './generators/homescreen';

figma.showUI(__html__, { width: 320, height: 400 });

figma.ui.onmessage = async (msg: { type: string; direction: string }) => {
  if (msg.type !== 'generate') return;

  const direction = msg.direction as Direction;

  try {
    // Remove previously generated pages
    // Figma requires >=1 page and won't remove the current page, so switch first
    const tempPage = figma.createPage();
    tempPage.name = '_temp';
    figma.currentPage = tempPage;
    const generatedPrefixes = ['📋', '🎨', '🔤', '📏', '🔲', '🧩', '📱'];
    for (const page of [...figma.root.children]) {
      if (page !== tempPage && generatedPrefixes.some(p => page.name.startsWith(p))) {
        page.remove();
      }
    }

    figma.notify('Loading fonts...', { timeout: 2000 });
    await loadFonts(direction);

    figma.notify('Creating variables...', { timeout: 2000 });
    createColorVariables(direction);
    createSpacingVariables();
    createRadiusVariables(direction);
    createTypographyVariables(direction);

    figma.notify('Creating styles...', { timeout: 2000 });
    createTextStyles(direction);
    createEffectStyles(direction);
    createGridStyle();

    figma.notify('Creating reference pages...', { timeout: 2000 });
    createCoverPage(direction);
    createColorsPage(direction);
    createTypographyPage(direction);
    createSpacingPage();
    createElevationPage(direction);
    createComponentsPage(direction);
    createScreenTemplatesPage();
    createHomeScreenPage(direction);

    // Remove temp page and any leftover default empty page
    for (const page of [...figma.root.children]) {
      if (page.name === '_temp' || (page.name === 'Page 1' && page.children.length === 0)) {
        page.remove();
      }
    }

    // Navigate to cover page
    const coverPage = figma.root.children.find(p => p.name === '📋 Cover');
    if (coverPage) {
      figma.currentPage = coverPage;
    }

    figma.notify('✓ Design system generated!', { timeout: 3000 });
  } catch (error) {
    figma.notify(`Error: ${error}`, { error: true, timeout: 5000 });
  }

  figma.closePlugin();
};
