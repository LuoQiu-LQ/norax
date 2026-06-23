# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Norax is a personal blog ("个人博客") built with Astro 6 and Tailwind CSS 4. Content and UI are largely in Chinese. The site is statically generated, but augmented at runtime with a small custom backend (views/likes/favorites/comments) reached via the `/api` prefix.

## Commands

- `npm run dev` — local dev server at `localhost:4321`
- `npm run build` — build static site to `./dist/`
- `npm run preview` — preview the production build
- `npm run astro check` — type-check `.astro` files (also `astro add`, etc.)
- `./deploy.sh` — build + deploy to the production server (see Deployment)

Requires Node >= 22.12.0. There is no test suite or linter configured.

## Architecture

- **Content collections** (`src/content.config.ts`): a single `posts` collection loaded via glob from `src/content/posts/**/*.{md,mdx}`. Frontmatter schema: `title`, `date`, `description`, required; `tags` and `featured` optional. Adding a post = adding a Markdown file with valid frontmatter; the build derives routes, tag pages, and archives from it.
- **Routing**: pages in `src/pages/`. `posts/[id].astro` generates a page per post via `getStaticPaths`; `tags/[tag].astro` generates a page per tag. `index.astro`, `archives.astro`, `tags.astro`, `about.astro` are the top-level pages.
- **Layouts**: `Layout.astro` is the base shell; `PostLayout.astro` wraps individual posts and contains all the client-side interactivity.
- **Markdown rendering**: Shiki with `github-light`/`github-dark` themes and line wrapping, configured in `astro.config.mjs`. MDX and sitemap integrations are enabled.
- **Styling**: Tailwind 4 via the Vite plugin (`@tailwindcss/vite`), not a PostCSS config. Global styles in `src/styles/global.css`. The theme uses custom semantic color names like `ink`, `ink-light`.

## Backend integration (important)

The site is static, but `PostLayout.astro` contains inline client-side JS that calls a separate backend at base URL `/api` (`const API = '/api'` near line 183). Endpoints used:

- `POST /api/views/:postId`, `POST /api/likes/:postId`, `POST /api/favorites/:postId`
- `GET /api/comments/:postId`, `POST` to create, `DELETE /api/comments/:commentId` (admin-only via token)

The backend is a separate service (SQLite + PM2 process `blog-backend` under `/var/www/backend` on the server) and is **not** part of this repo. When changing comment/like/view behavior, the frontend contract lives entirely in `PostLayout.astro`.

## Deployment

`deploy.sh` builds locally, then over SSH (server `39.104.74.119`, path `/var/www/norax`): wipes the remote web dir, uploads `dist/` and the raw `src/content/posts/` Markdown to `raw_posts/`, fixes Nginx ownership, reloads Nginx, and restarts the `blog-backend` PM2 process (which triggers SQLite cleanup of deleted posts). The raw `.md` upload is what lets the backend reconcile its database against currently-existing posts.
