// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';

import mdx from '@astrojs/mdx';

import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()]
  },

  markdown: {
    shikiConfig: {
      themes: {
        light: 'github-light',
        dark: 'github-dark'
      },
      wrap: true,
    },
  },

  devToolbar: {
    enabled: false
  },

  integrations: [mdx(), sitemap()],
});