# Premium UI/UX Design System

## Design direction
Premium, calm, modern, mobile-first and utility-focused. The interface should feel trustworthy and efficient rather than crowded. Use a restrained neutral foundation, one confident primary accent, and limited semantic colors. Do not use gradients or glass effects everywhere; reserve visual emphasis for primary actions and important states.

## Proposed design tokens
These are starting points, not final brand decisions:
- Background: warm/neutral near-white in light mode; deep neutral in dark mode.
- Surface: cards and sheets with subtle separation.
- Primary: saturated blue/indigo or another tested accessible brand accent.
- Success, warning, error: semantic colors with text/icon support, never color alone.
- Typography: platform-friendly sans-serif, clear hierarchy, dynamic text support.
- Spacing scale: 4, 8, 12, 16, 20, 24, 32.
- Corner radius: 12–20 for cards/sheets; consistent smaller radius for controls.
- Touch targets: aim for at least 44pt iOS / 48dp Android where practical.
- Motion: short purposeful transitions; respect reduced-motion settings.

## Component system
- Primary, secondary, tertiary, and destructive buttons.
- Tool tiles with icon, title, concise helper text.
- File row and document thumbnail.
- Page thumbnail with selection/reorder state.
- Progress panel with cancel action.
- Empty state with one clear next action.
- Permission rationale and fallback action.
- Error banner/dialog with recovery guidance.
- Bottom sheet for quick settings and export options.
- Pro purchase sheet explaining one-time payment and ad removal.
- Offline/feature-unavailable message where needed.

## UX rules
- One dominant action per screen.
- Keep camera controls minimal and readable.
- Group PDF tools by task, not by internal implementation.
- Show preview before destructive or quality-reducing operations.
- Use Save As by default.
- Do not interrupt active editing with interstitial ads.
- Show real progress; never animate fake progress to imply work is complete.
- Use clear language, not raw engine errors.
- Explain permissions when needed and provide alternatives.
- Make privacy claims precise and verifiable.

## Accessibility
- Screen-reader labels and semantic order.
- Contrast target aligned with WCAG guidance where applicable.
- Support text scaling and dynamic type.
- Keyboard/focus support for iPad and external keyboards where relevant.
- Visible focus states.
- Reduced motion.
- Do not rely on color alone to indicate status.
- Test with VoiceOver and TalkBack.

## Dark mode
All surfaces, thumbnails, toolbars, dialogs, annotation colors and system bars must be reviewed in dark mode. Do not simply invert colors. PDF page content itself must remain faithful to the document.
