# EE_SKILLS

Eric 的个人技能集，同时兼容 Codex 和 Claude Code。

## 技能列表

### ppt-image-to-svg

先用图片生成创建精美的 PPT 风格 PNG，保存到项目中，再手绘为 PowerPoint 可编辑的 SVG。

适用场景：
- 先产出高质量的 PPT 风格图片作为视觉基准；
- 再基于 PNG 手绘匹配的 SVG；
- SVG 文本块适合导入 PowerPoint 后继续编辑；
- 正文段落保持为单个 `<text>` 元素，不按行拆分。

### read-image

通过独立配置的视觉 API（mimo-v2.5）读图，不依赖当前使用的对话模型。Codex / Claude Code 均可使用。

适用场景：
- 描述、分析图片内容；
- 从截图或照片中转录代码 / 文字；
- 提取错误信息和堆栈跟踪；
- 理解图表、架构图、UI 截图等视觉内容。

支持格式：JPG / JPEG / PNG / GIF / WebP / BMP / TIFF。

配置方式：编辑 `skills/read-image/config.yaml` 中的 `base_url` / `auth_token` / `model` 等字段即可适配不同 API。

## 安装

### Codex

```powershell
Copy-Item -Recurse .\skills\ppt-image-to-svg "$env:USERPROFILE\.codex\skills\ppt-image-to-svg"
Copy-Item -Recurse .\skills\read-image "$env:USERPROFILE\.codex\skills\read-image"
```

### Claude Code

```powershell
Copy-Item -Recurse .\skills\ppt-image-to-svg "$env:USERPROFILE\.claude\skills\ppt-image-to-svg"
Copy-Item -Recurse .\skills\read-image "$env:USERPROFILE\.claude\skills\read-image"
```

安装后在对话中通过技能名调用即可。
