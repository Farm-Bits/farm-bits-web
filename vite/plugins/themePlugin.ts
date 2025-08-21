import type { Plugin } from 'vite';
import fs from 'fs';
import path from 'path';

type ColorShades = {
  light?: string;
  base?: string;
  dark?: string;
  darker?: string;
  [key: string]: string | undefined;
};

type ColorConfig = {
  brand?: {
    green?: ColorShades;
    blue?: ColorShades;
  };
  feature?: {
    green?: string;
    blue?: string;
    purple?: string;
  };
  primary?: string;
  secondary?: string;
  [key: string]: any;
};

function getRGBValues(hexColor: string): number[] {
  const hex = hexColor.replace('#', '');
  try {
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return [r, g, b];
  } catch (error) {
    console.error(`Error converting color ${hexColor} to RGB:`, error);
    return [0, 0, 0];
  }
}

function generateCSSVariables(colors: ColorConfig): string {
  let css = '\n/* Generated Theme Variables: DO NOT EDIT OR REMOVE THIS SECTION */\n:root {\n';

  // Handle simple colors (primary, secondary)
  if (colors.primary) {
    const rgb = getRGBValues(colors.primary).join(', ');
    css += `  --primary-color: ${colors.primary};\n`;
    css += `  --primary-color-rgb: ${rgb};\n`;
    css += `  --cui-primary: ${colors.primary};\n`;
    css += `  --cui-primary-rgb: ${rgb};\n\n`;
  }

  if (colors.secondary) {
    const rgb = getRGBValues(colors.secondary).join(', ');
    css += `  --secondary-color: ${colors.secondary};\n`;
    css += `  --secondary-color-rgb: ${rgb};\n`;
    css += `  --cui-secondary: ${colors.secondary};\n`;
    css += `  --cui-secondary-rgb: ${rgb};\n\n`;
  }

  // Handle brand colors (nested structure)
  if (colors.brand) {
    Object.entries(colors.brand).forEach(([colorName, shades]) => {
      if (typeof shades === 'object' && shades !== null) {
        Object.entries(shades).forEach(([shade, value]) => {
          if (typeof value === 'string') {
            const rgb = getRGBValues(value).join(', ');
            const varName = shade === 'base' ? colorName : `${colorName}-${shade}`;

            css += `  --brand-${varName}-color: ${value};\n`;
            css += `  --brand-${varName}-color-rgb: ${rgb};\n`;
            css += `  --cui-brand-${varName}: ${value};\n`;
            css += `  --cui-brand-${varName}-rgb: ${rgb};\n`;
          }
        });
        css += '\n';
      }
    });
  }

  // Handle feature colors
  if (colors.feature) {
    Object.entries(colors.feature).forEach(([colorName, value]) => {
      if (typeof value === 'string') {
        const rgb = getRGBValues(value).join(', ');
        css += `  --feature-${colorName}-color: ${value};\n`;
        css += `  --feature-${colorName}-color-rgb: ${rgb};\n`;
        css += `  --cui-feature-${colorName}: ${value};\n`;
        css += `  --cui-feature-${colorName}-rgb: ${rgb};\n`;
      }
    });
    css += '\n';
  }

  // Handle any other color definitions at the root level
  Object.entries(colors).forEach(([colorName, value]) => {
    // Skip already processed colors and nested objects
    if (['primary', 'secondary', 'brand', 'feature'].includes(colorName) || typeof value !== 'string') {
      return;
    }

    const rgb = getRGBValues(value).join(', ');
    css += `  --${colorName}-color: ${value};\n`;
    css += `  --${colorName}-color-rgb: ${rgb};\n`;
    css += `  --cui-${colorName}: ${value};\n`;
    css += `  --cui-${colorName}-rgb: ${rgb};\n`;
  });

  css += '}\n\n';

  // Add utility classes for easier usage
  css += '/* Utility classes for colors */\n';
  css += '.bg-primary { background-color: var(--primary-color); }\n';
  css += '.bg-secondary { background-color: var(--secondary-color); }\n';
  css += '.text-primary { color: var(--primary-color); }\n';
  css += '.text-secondary { color: var(--secondary-color); }\n';
  css += '.border-primary { border-color: var(--primary-color); }\n';
  css += '.border-secondary { border-color: var(--secondary-color); }\n\n';

  if (colors.brand?.green) {
    css += '.bg-brand-green { background-color: var(--brand-green-color); }\n';
    css += '.bg-brand-green-light { background-color: var(--brand-green-light-color); }\n';
    css += '.bg-brand-green-dark { background-color: var(--brand-green-dark-color); }\n';
    css += '.text-brand-green { color: var(--brand-green-color); }\n';
    css += '.border-brand-green { border-color: var(--brand-green-color); }\n\n';
  }

  if (colors.brand?.blue) {
    css += '.bg-brand-blue { background-color: var(--brand-blue-color); }\n';
    css += '.bg-brand-blue-light { background-color: var(--brand-blue-light-color); }\n';
    css += '.bg-brand-blue-dark { background-color: var(--brand-blue-dark-color); }\n';
    css += '.text-brand-blue { color: var(--brand-blue-color); }\n';
    css += '.border-brand-blue { border-color: var(--brand-blue-color); }\n\n';
  }

  // Add CoreUI button overrides for custom colors
  css += '/* CoreUI Button Overrides */\n';

  // Fix base button class to not interfere with outline buttons
  css += '.btn {\n';
  css += '  --cui-btn-color: var(--cui-body-color);\n';
  css += '  --cui-btn-bg: transparent;\n';
  css += '  --cui-btn-border-color: transparent;\n';
  css += '  --cui-btn-hover-color: var(--cui-body-color);\n';
  css += '  --cui-btn-hover-bg: transparent;\n';
  css += '  --cui-btn-hover-border-color: transparent;\n';
  css += '}\n\n';

  // Generate button styles for all defined colors
  const allColors = {
    ...(colors.primary && { primary: colors.primary }),
    ...(colors.secondary && { secondary: colors.secondary }),
    // Add other root level colors that are strings
    ...Object.fromEntries(
      Object.entries(colors).filter(([key, value]) => 
        !['primary', 'secondary', 'brand', 'feature'].includes(key) && typeof value === 'string'
      )
    )
  };

  Object.entries(allColors).forEach(([colorName, colorValue]) => {
    if (typeof colorValue === 'string') {
      const darkColorVar = colorName === 'primary' ? 'var(--brand-green-dark-color)' :
                          colorName === 'secondary' ? 'var(--brand-blue-dark-color)' :
                          `var(--${colorName}-dark-color, ${colorValue})`;

      // Solid button
      css += `.btn-${colorName} {\n`;
      css += `  --cui-btn-color: white !important;\n`;
      css += `  --cui-btn-bg: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-border-color: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-hover-color: white !important;\n`;
      css += `  --cui-btn-hover-bg: ${darkColorVar} !important;\n`;
      css += `  --cui-btn-hover-border-color: ${darkColorVar} !important;\n`;
      css += `  --cui-btn-focus-shadow-rgb: var(--${colorName}-color-rgb) !important;\n`;
      css += `  --cui-btn-active-color: white !important;\n`;
      css += `  --cui-btn-active-bg: ${darkColorVar} !important;\n`;
      css += `  --cui-btn-active-border-color: ${darkColorVar} !important;\n`;
      css += `}\n\n`;

      // Outline button
      css += `.btn-outline-${colorName} {\n`;
      css += `  --cui-btn-color: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-bg: transparent !important;\n`;
      css += `  --cui-btn-border-color: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-hover-color: white !important;\n`;
      css += `  --cui-btn-hover-bg: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-hover-border-color: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-focus-shadow-rgb: var(--${colorName}-color-rgb) !important;\n`;
      css += `  --cui-btn-active-color: white !important;\n`;
      css += `  --cui-btn-active-bg: ${darkColorVar} !important;\n`;
      css += `  --cui-btn-active-border-color: ${darkColorVar} !important;\n`;
      css += `  --cui-btn-disabled-color: var(--${colorName}-color) !important;\n`;
      css += `  --cui-btn-disabled-bg: transparent !important;\n`;
      css += `  --cui-btn-disabled-border-color: var(--${colorName}-color) !important;\n`;
      css += `  --cui-gradient: none !important;\n`;
      css += `}\n\n`;
    }
  });

  // Always add the end boundary marker at the very end
  css += '/* End Generated Theme Variables */';

  return css;
}

export default function themePlugin(): Plugin {
  return {
    name: 'vite-plugin-theme',
    buildStart: async () => {
      try {
        const tailwindConfig = require('../../tailwind.config.js');
        const colors = tailwindConfig.theme?.extend?.colors || tailwindConfig.default?.theme?.extend?.colors;

        if (!colors) {
          console.warn('No colors found in Tailwind config');
          return;
        }

        const cssPath = path.resolve(__dirname, '../../app/frontend/styles/application.css');
        const existingCSS = fs.readFileSync(cssPath, 'utf8');
        const themeCSS = generateCSSVariables(colors);

        // Updated regex to match the entire generated section from start marker to end marker
        const themeRegex = /\/\* Generated Theme Variables: DO NOT EDIT OR REMOVE THIS SECTION \*\/[\s\S]*?\/\* End Generated Theme Variables \*\/\n?/;

        let updatedCSS = '';
        if (themeRegex.test(existingCSS)) {
          // Replace existing theme section
          updatedCSS = existingCSS.replace(themeRegex, themeCSS.trim() + '\n');
        } else {
          // Add theme section at the beginning (after @tailwind directives)
          const tailwindRegex = /(@tailwind[^;]*;[\s\S]*?)(\n\n|$)/;
          if (tailwindRegex.test(existingCSS)) {
            updatedCSS = existingCSS.replace(tailwindRegex, `$1\n${themeCSS}`);
          } else {
            updatedCSS = themeCSS + existingCSS;
          }
        }

        fs.writeFileSync(cssPath, updatedCSS);
        console.log('Theme CSS variables generated successfully!');

      } catch (error) {
        console.error('Error generating theme:', error);
      }
    }
  };
}
