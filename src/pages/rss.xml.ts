import rss from '@astrojs/rss'
import { getCollection } from 'astro:content'
import type { APIContext } from 'astro'

export async function GET(context: APIContext) {
  const posts = await getCollection('posts')
  const sorted = posts.sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf())

  return rss({
    title: '落秋笔记',
    description: '一个极简文艺的个人博客',
    site: context.site ?? 'https://www.luoqiu.xyz',
    items: sorted.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.date,
      link: `/posts/${post.id}/`,
      categories: post.data.tags,
    })),
    customData: '<language>zh-CN</language>',
  })
}
