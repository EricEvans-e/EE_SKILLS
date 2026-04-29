# EE_SKILLS

Personal Codex skills by Eric.

## Skills

### ppt-image-to-svg

Generate a polished PNG for a PowerPoint slide with image generation, save it into the project, then redraw it as a PowerPoint-friendly editable SVG.

Use this skill when you want:

- a beautiful PPT-style image generated first;
- a matching SVG rebuilt from the generated PNG;
- SVG text blocks that remain easier to edit after importing into PowerPoint;
- body paragraphs kept as one `<text>` element instead of line-by-line SVG text.

## Install

Copy the skill folder into your Codex skills directory:

```powershell
Copy-Item -Recurse .\skills\ppt-image-to-svg "$env:USERPROFILE\.codex\skills\ppt-image-to-svg"
```

Then invoke it in Codex:

```text
[$ppt-image-to-svg](C:\Users\Eric\.codex\skills\ppt-image-to-svg\SKILL.md)
```

