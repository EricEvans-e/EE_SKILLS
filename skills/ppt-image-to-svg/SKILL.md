---
name: ppt-image-to-svg
description: Generate a polished PNG for a PowerPoint slide with image generation, save it into the project, then redraw it as a PowerPoint-friendly editable SVG. Use when the user asks to make a PPT page/infographic/slide visual, first use image gen, convert a generated PNG into SVG, redraw a PNG as SVG, or keep text easy to edit in PowerPoint.
---

# PPT Image To SVG

## Overview

Use this skill for the full PPT visual workflow: understand the slide request, generate the most attractive PNG first, save that PNG, then hand-redraw a matching SVG optimized for PowerPoint conversion and text editing.

The PNG is the visual target. The SVG is the editable PPT asset. When the two conflict, prioritize PPT editability in the SVG.

Before writing the SVG, read `references/ppt-svg-rules.md`.

## Workflow

1. Confirm the slide content, target aspect ratio, and output directory from the user's context.
2. Use the native `image_gen` tool to generate a beautiful PNG reference.
3. Locate the generated PNG under `$CODEX_HOME/generated_images/...` and copy it into the project output directory.
4. Redraw the SVG manually from the PNG reference using SVG primitives. Do not vector-trace blindly and do not embed the PNG.
5. Before finishing the SVG, make an icon/decorative-element inventory from the PNG and verify the SVG matches it.
6. Save the SVG beside the PNG.
7. Validate the PNG exists, the SVG parses as XML, the SVG follows PPT-editable text rules, and icons match the PNG.
8. Update a local README or asset list only when the current project already uses one or the user asks for handoff documentation.

## Output Naming

Use clear Chinese or user-provided page names.

- PNG: `<slide-name>-image.png`
- SVG: `<slide-name>-ppt-edit.svg`

If a file exists, create `-v2`, `-v3`, etc. Do not overwrite existing user files unless the user explicitly requests replacement.

## PNG Generation Rules

Generate the PNG first, even if the final requested deliverable is SVG.

Prompt image generation for:

- polished PPT/infographic aesthetics;
- strong hierarchy and readability;
- the user's exact subject matter and text content;
- the intended page ratio, usually 16:9;
- the style needed by the project, such as engineering, academic, business, or tutorial.

After generation, copy the selected PNG into the working project. Do not leave the only usable copy in `$CODEX_HOME/generated_images`.

## SVG Redraw Rules

Use the PNG as a visual reference, not as SVG content.

Required:

- Use a complete `<svg>` root with `xmlns`, `width`, `height`, `viewBox`, `title`, and `desc`.
- Prefer `1600 x 900` or another 16:9 canvas for widescreen PPT.
- Use basic elements: `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, simple `path`, simple `linearGradient`, and `text`.
- Group logical regions with clear `<g id="...">` names.
- Put styles directly on elements where possible.
- Use common font fallback: `Microsoft YaHei, PingFang SC, Noto Sans SC, Arial, sans-serif`.

Forbidden for PPT-editable SVG:

- `<image>` for the generated PNG or any main content;
- `filter`, `drop-shadow`, `blur`, `mask`, `clipPath`;
- complex nested transform chains;
- external CSS, web fonts, and external linked assets;
- `textLength`, `lengthAdjust`, or forced text fitting that can confuse PPT conversion.

## Text Editability Rule

This is the most important rule.

For PPT editing priority, every logical text block must be a single `<text>` element.

- One body paragraph equals one `<text>`.
- Do not split one paragraph into multiple `<text>` lines for SVG visual wrapping.
- Do not use multiple `<tspan>` elements to simulate line breaks.
- A red heading and its black body paragraph may be separate `<text>` elements because they are different style/logical blocks.
- Accept that SVG preview text may look smaller, longer, or less beautiful than the PNG.

The final SVG exists to become editable in PowerPoint. Text editability wins over SVG preview beauty.

## Icon Fidelity Rule

The SVG must not invent or swap icons from the generated PNG.

Before drawing the SVG, inspect the PNG and list the important icons and decorative symbols:

- count;
- meaning, such as checkmark, warning mark, arrow, gear, badge, dot, or label;
- approximate position and size;
- orientation;
- repeated pattern behavior.

When redrawing:

- match icon meaning first;
- match icon count and placement second;
- use simple editable geometry for the icon whenever possible;
- simplify gradients and tiny details, but do not change a checkmark into another symbol or a warning symbol into a decorative mark;
- if an icon is unclear, inspect the PNG again before drawing rather than guessing.

This cannot be perfectly guaranteed for every generated raster image while also keeping the SVG PowerPoint-editable. Exact icon fidelity may require complex paths or embedded image fragments, which harms editability. The correct default is: preserve icon semantics and layout with simple editable SVG geometry.

## Validation Checklist

Before finishing:

- Confirm the PNG was copied to the project directory.
- Compare the PNG and SVG icon inventory: same icon meaning, count, rough position, and orientation.
- Parse the SVG as XML.
- Confirm the SVG contains no `<image>`, `<filter>`, `<mask>`, `<clipPath>`, `blur`, `class=`, `<tspan>`, `textLength`, or `lengthAdjust`.
- Count `<text>` elements and verify each body paragraph appears exactly once inside one complete `<text>...</text>`.
- Confirm the SVG uses clear groups and a 16:9 PPT-friendly canvas unless the user requested another ratio.
- Tell the user explicitly if the SVG preview sacrifices text beauty for PPT editability.

## Final Response

Keep the final response short. Include:

- PNG path;
- SVG path;
- validation summary;
- icon fidelity note when the slide contains icons;
- note that the SVG is PPT text-editability first if relevant.
