// 公共格式化工具，供各页面与布局复用

/** 完整日期：2024年3月27日 */
export function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return d.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

/** 简短日期（归档用）：3月27日 */
export function formatDateShort(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return d.toLocaleDateString('zh-CN', { month: 'long', day: 'numeric' })
}

/**
 * 估算阅读时间（分钟）。
 * 传入文章正文（post.body），按中文约 300 字/分钟估算，至少 1 分钟。
 */
export function getReadingTime(content: string): number {
  if (!content) return 1
  // 去掉 Markdown 语法噪声后按字符数估算
  const text = content.replace(/[#>*`_~\-\[\]()!]/g, '')
  return Math.max(1, Math.ceil(text.length / 300))
}
