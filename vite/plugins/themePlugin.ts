import type { Plugin } from 'vite';
import fs from 'fs';
import path from 'path';

interface ColorShades {
  light?: string;
  base?: string;
  dark?: string;
  darker?: string;
  [key: string]: string | undefined;
};

interface ColorConfig {
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

  // Add utility classes for easier usage
  css += '}\n\n';
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

        const themeRegex = /\/\* Generated Theme Variables: DO NOT EDIT OR REMOVE THIS SECTION \*\/[\s\S]*?\}/;

        const updatedCSS = themeRegex.test(existingCSS)
          ? existingCSS.replace(themeRegex, themeCSS.trim())
          : existingCSS + themeCSS;

        fs.writeFileSync(cssPath, updatedCSS);
        console.log('Theme CSS variables generated successfully!');

      } catch (error) {
        console.error('Error generating theme:', error);
      }
    }
  };
}
