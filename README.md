# EE_SKILLS

Eric 的个人 Codex 技能集。

## 技能列表

### ppt-image-to-svg

先用图片生成创建精美的 PPT 风格 PNG，保存到项目中，再手绘为 PowerPoint 可编辑的 SVG。

适用场景：
- 先产出高质量的 PPT 风格图片作为视觉基准；
- 再基于 PNG 手绘匹配的 SVG；
- SVG 文本块适合导入 PowerPoint 后继续编辑；
- 正文段落保持为单个 `<text>` 元素，不按行拆分。

### read-image

通过视觉模型（mimo-v2.5）桥接，读取和分析图片内容。

适用场景：
- 描述、分析图片内容；
- 从截图或照片中转录代码 / 文字；
- 提取错误信息和堆栈跟踪；
- 理解图表、架构图、UI 截图等视觉内容。

支持格式：JPG / JPEG / PNG / GIF / WebP / BMP / TIFF。

## 安装

将技能文件夹复制到 Codex skills 目录：

```powershell
# ppt-image-to-svg
Copy-Item -Recurse .\skills\ppt-image-to-svg "$env:USERPROFILE\.codex\skills\ppt-image-to-svg"

# read-image
Copy-Item -Recurse .\skills\read-image "$env:USERPROFILE\.codex\skills\read-image"
```

安装后在 Codex 中通过技能名调用即可。
