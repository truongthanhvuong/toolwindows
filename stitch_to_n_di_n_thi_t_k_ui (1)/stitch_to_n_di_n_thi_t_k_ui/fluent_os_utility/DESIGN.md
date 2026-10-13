---
name: Fluent OS Utility
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c3c6d7'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#8d90a0'
  outline-variant: '#434655'
  surface-tint: '#b4c5ff'
  primary: '#b4c5ff'
  on-primary: '#002a78'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#0053db'
  secondary: '#adc6ff'
  on-secondary: '#002e6a'
  secondary-container: '#0566d9'
  on-secondary-container: '#e6ecff'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#007d55'
  on-tertiary-container: '#bdffdb'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-md:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  metric-num:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  body-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  code-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-lg: 1rem
  margin: 1rem
  margin-window: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system establishes a high-performance, native desktop utility experience at the intersection of Windows 11 Fluent Design (Mica/Acrylic material logic) and macOS Human Interface Guidelines (vibrant restraint, disciplined metrics, and ergonomic control layouts). 

### Target Audience & Personality
- **Audience:** System administrators, IT engineers, power users, and PC builders requiring mission-critical diagnostics, automated deployment, and deep OS configuration without clutter or distraction.
- **Personality:** Precision-engineered, dependable, responsive, and surgically clear. It replaces the fragmented, high-saturation, chaotic desktop utility styling with an executive-tier, cohesive dashboard aesthetic.

### Aesthetic Movement & Philosophy
The system combines **Translucent Materiality (Fluent Mica/Acrylic)** with **Structured Utilitarian Hierarchy**. 
- Layers utilize subtle background blur, translucent surface fills, and ultra-crisp `1px` translucent edge borders to simulate real desktop glass and layered metal.
- Content is grouped logically into high-contrast metric pods, unified segmented controls, and organized toggle matrices that minimize visual fatigue while conveying high information density.

## Colors

The system uses a calibrated palette tailored for deep focus and instant glanceability across hardware monitoring cards and configuration panels.

### Palette Architecture
- **Primary & Accent (`#2563EB` & `#3B82F6`):** Electric Blue and Vivid Cobalt are used for active sidebar indicators, primary commit buttons, focused tab selections, and verified status highlights.
- **Success (`#10B981`):** Emerald Green indicates healthy telemetry, active services, verified licenses (`PRO / Lifetime`), and completed deployment batches.
- **Warning (`#F59E0B`):** Amber signals elevated system privileges, thermal cautions, and restart-dependent adjustments.
- **Danger (`#EF4444`):** Rose Red denotes critical operations, destructive partition actions, and unrecoverable tweaks.
- **Dark Neutral Architecture:**
  - Base Window / Canvas: `#090D16` (Deep Midnight Mica)
  - Sidebar / Chrome: `rgba(15, 23, 42, 0.75)` with 20px blur
  - Surface Pods (Cards & Sections): `rgba(30, 41, 59, 0.65)`
  - Elevated Popovers & Menus: `#1E293B`
  - Subtle Borders & Dividers: `rgba(255, 255, 255, 0.08)` to `rgba(255, 255, 255, 0.12)`
- **Light Mode Mirror:**
  - Base: `#F8FAFC`, Surface Pods: `rgba(255, 255, 255, 0.85)`, Borders: `rgba(0, 0, 0, 0.08)`, Text Primary: `#0F172A`.

## Typography

The typography scale utilizes **Inter** (seamlessly interchangeable with native desktop *Segoe UI Variable* or *SF Pro Text*), prioritizing clarity, tight tracking for numerical data, and structural hierarchy across compact application viewports.

### Hierarchy Guidelines
- **Metric Figures (`metric-num`):** Used for large hardware performance readouts (CPU %, RAM GB, Disk I/O). Uses tabular figures (`font-variant-numeric: tabular-nums`) to prevent layout shifts during live polling.
- **Section Headers (`headline-lg`, `headline-md`):** Clear, semibold weights without excessive decorative drop-shadows or outlines.
- **Status Badges & Eyebrows (`label-md`, `label-sm`):** Rendered in crisp semibold or medium weights with subtle letter spacing for rapid scanning of license tiers, service statuses, and category headers.
- **Body & Configuration Labels (`body-md`):** Sized conservatively at 13px with 18px line height to allow high UI density across dual-pane configurations without visual overcrowding.

## Layout & Spacing

The layout model is optimized for desktop window environments with responsive resizing, split-view panels, and fixed-sidebar utility workflows.

### Window & Grid Architecture
- **Desktop Canvas (>=1200px):** 
  - Fixed-width collapsible Master Navigation Sidebar: `240px` to `260px`.
  - Main Viewport: Flexible grid system (6 or 12 columns) housing metric tiles, tab strips, and dual-column tweak lists.
  - Section Spacing: `1.25rem` outer window margins, `0.75rem` gutters between telemetry cards.
- **Compact Desktop / Tablet Viewport (<1024px):**
  - Sidebar collapses into an icon-only rail (`64px`).
  - Metric pods reflow into 2-column or 3-column rows.
  - Action bars lock to the bottom edge or collapse into contextual action menus.

### Density & Vertical Rhythm
Elements adhere strictly to an 8px base rhythm with 4px sub-steps for compact control clusters (checkbox rows, segmented buttons). Spacing tokens are reserved strictly for layout distances and card padding to maintain geometric discipline.

## Elevation & Depth

Visual hierarchy uses frosted translucent materials, ambient shadow occlusion, and interior hairline borders rather than heavy drop shadows.

### Material Surfaces & Glassmorphism
1. **Window Background (Level 0):** Deep Mica canvas with subtle noise and an ambient radial gradient overlay to eliminate flat-matte monotony.
2. **Sidebar Rail (Level 1):** `backdrop-filter: blur(24px)` with a 75% dark fill. Right border is a crisp `1px solid rgba(255, 255, 255, 0.08)`.
3. **Metric Cards & Tool Panels (Level 2):** 
   - Surface: `rgba(255, 255, 255, 0.04)` on Dark, `rgba(255, 255, 255, 0.70)` on Light.
   - Border: Hairline `1px solid rgba(255, 255, 255, 0.10)`.
   - Shadow: `0 4px 16px -2px rgba(0, 0, 0, 0.25)`.
4. **Active Controls & Flyouts (Level 3):**
   - Solid fill: `#1E293B` or `#2563EB` with an ambient edge rim: `inset 0 1px 0 rgba(255, 255, 255, 0.15)`.
   - Shadow: `0 8px 24px -4px rgba(0, 0, 0, 0.35)`.

## Shapes

The design system employs a **Rounded** shape philosophy (Level 2), aligning with modern Fluent 2 and macOS Sonoma window aesthetics.

- **Micro Controls & Checkboxes:** `6px` radius (`rounded-sm`).
- **Standard Buttons, Inputs, & Segmented Tabs:** `8px` radius (`rounded-md`).
- **Telemetry Pods, Cards, & Section Shells:** `12px` to `16px` radius (`rounded-lg`).
- **Badges, Status Pills, & Quick Action Toggles:** Full pill radius (`rounded-full` / `9999px`) to immediately distinguish live system states from interactive functional cards.

## Components

### 1. Navigation Sidebar & Window Header
- **Window Titlebar:** Native macOS/Windows window control placement with embedded breadcrumbs and license chips (`PRO • Lifetime` in Emerald tint).
- **Navigation Items:** 36px height, 8px border radius, subtle hover states (`rgba(255, 255, 255, 0.06)`). Active navigation items feature a solid accent indicator pill on the left border or a tinted blue background pill (`rgba(37, 99, 235, 0.15)`) with an Electric Blue icon and text.

### 2. Metrics & Telemetry Cards
- **Card Shell:** Frosted glass surface, 1px perimeter border, padded at `space-lg` (16px).
- **Header:** 16px icon with colored container badge, card title (13px Semibold), and dynamic chevron or status dot.
- **Data Display:** Bold tabular number (`28px`), paired with miniature secondary metrics below (e.g., User %, System %, Temp °C).
- **Progress Gauge / Dot Matrix:** Mini dot array or smooth linear progress bar using accent gradients indicating real-time system consumption.

### 3. Segmented Controls & Action Buttons
- **Segmented Switcher:** Encapsulated pill/rounded-md container with a sliding elevated thumb for tab categories (e.g., 1m / 5m / 15m / 1h or Mode switches).
- **Primary Action Buttons:** Electric blue gradient (`#2563EB` to `#1D4ED8`), inset top highlight for tactile depth, 8px radius, white semibold text.
- **Destructive Buttons:** Subtle rose border with translucent red fill; transitions to solid red on hover.

### 4. Configuration Matrices & Toggle Switches
- **Tweak Rows:** Clean list presentation with alternating subtle fills on hover. Checkbox or toggle alignment strictly anchored to a unified vertical guide.
- **Desktop Toggle Switches:** macOS-style fluid toggle switch (40px x 22px) with smooth 200ms cubic-bezier transition, using Emerald Green or Electric Blue for active states.

### 5. Data Grids & Software Catalog Tiles
- **Tile Card:** Compact grid layout for software and tweak items. Left-aligned high-res app icon (24px x 24px), label truncated cleanly, right-aligned checkbox or radio button.
- **Selection State:** Active cards display a 1px Electric Blue ring (`#2563EB`) and a subtle blue background tint.