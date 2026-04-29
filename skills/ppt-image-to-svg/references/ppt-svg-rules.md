# PPT-Friendly SVG Rules

Use this reference before redrawing a generated PNG as SVG for PowerPoint.

## Priority Order

1. PowerPoint imports the SVG reliably.
2. PowerPoint can convert the SVG to shapes.
3. Text remains easy to edit.
4. Icons and symbols keep the same meaning, count, position, and orientation as the PNG.
5. Object structure is understandable after ungrouping.
6. Visual layout stays close to the generated PNG.

If a visual flourish harms PPT editability, simplify it.

## Canvas

Use a complete SVG root:

```xml
<svg
  xmlns="http://www.w3.org/2000/svg"
  width="1600"
  height="900"
  viewBox="0 0 1600 900"
  version="1.1"
  role="img"
  aria-labelledby="title desc">
  <title id="title">页面标题</title>
  <desc id="desc">文件说明</desc>
</svg>
```

Prefer `1600 x 900` for 16:9 slides. Use direct coordinates rather than complex transforms.

## Shapes

Prefer:

- `rect` for cards, panels, labels, and bands;
- `circle` / `ellipse` for badges and markers;
- `line` / `polyline` for connectors;
- `polygon` for simple arrows and geometric panels;
- simple `path` only where primitives are insufficient;
- simple `linearGradient` for light depth.

Use `rect + rx` for rounded rectangles:

```xml
<rect x="30" y="136" width="736" height="208" rx="24" fill="#ffffff" />
```

Do not draw ordinary cards as complex paths.

## Grouping

Group by logic:

```xml
<g id="page-background">...</g>
<g id="main-title">...</g>
<g id="comparison-row-1">...</g>
<g id="text-layer">...</g>
```

Keep groups shallow and readable. Use names that describe the slide structure, not arbitrary numbers.

## Icons and Decorative Symbols

Generated PNGs often contain badges, checkmarks, warning marks, arrows, dots, gears, or other small symbols. These are easy to redraw incorrectly. Treat icon matching as an explicit task, not a decorative afterthought.

Before drawing, make a quick inventory:

| Field | What to capture |
|---|---|
| Count | How many instances appear |
| Meaning | Checkmark, warning mark, arrow, gear, badge, label, etc. |
| Position | Left/right/top/bottom region and relationship to cards |
| Orientation | Direction, rotation, or mirrored state |
| Style | Circle badge, line icon, filled shape, outlined shape |

Redraw rules:

- Do not replace the PNG's icon with a different symbol.
- Preserve semantic meaning before visual polish.
- Preserve repeated icon count and approximate placement.
- Use editable primitives: `circle`, `line`, `polyline`, `polygon`, and simple `path`.
- Simplify tiny highlights and complex gradients when needed.
- If exact fidelity is required, explain the tradeoff: complex paths or image fragments improve visual match but reduce PPT editability.

This issue cannot be fully rooted out for every generated raster image because the PNG has no original vector structure. It can be controlled by explicit inventory plus final comparison.

## Text

For PowerPoint editing, text objects matter more than SVG visual wrapping.

Rules:

- One logical text block equals one `<text>`.
- One body paragraph must be one `<text>`.
- Do not split one paragraph into line-by-line `<text>`.
- Do not use `<tspan>` to simulate paragraph wrapping.
- Red headings and black body paragraphs may be separate `<text>` elements.
- Use smaller font sizes or wider text zones before considering any text split.
- Accept imperfect SVG preview text if it improves PPT editability.

Recommended font:

```xml
font-family="Microsoft YaHei, PingFang SC, Noto Sans SC, Arial, sans-serif"
```

## Avoid

Avoid these in PPT-editable SVG:

- `<image>` for main content or generated PNG embedding;
- `filter`, `drop-shadow`, `blur`, `feGaussianBlur`;
- `mask`, `clipPath`, `pattern`, `blend-mode`;
- external CSS, classes required for appearance, web fonts;
- complex nested transforms;
- `textLength` and `lengthAdjust`.

## Validation

Minimum validation:

- XML parses.
- No forbidden SVG features are present.
- Icon inventory matches the PNG: same meaning, count, rough position, and orientation.
- Body paragraphs are each present exactly once inside a single `<text>`.
- SVG has `title`, `desc`, `width`, `height`, and `viewBox`.
- Visual structure roughly matches the PNG: same main regions, hierarchy, colors, and important decorations.

PowerShell checks can include:

```powershell
[xml](Get-Content -LiteralPath $svg -Raw -Encoding UTF8) | Out-Null
Select-String -LiteralPath $svg -Pattern '<image','<filter','<mask','<clipPath','blur','<tspan','textLength','lengthAdjust','class=' -CaseSensitive
(Select-String -LiteralPath $svg -Pattern '<text ').Count
```
