# Component Specs — cwclark.com

## Navigation
- Position: fixed top, full width
- Background: transparent on load → white on scroll (headroom.js behavior)
- Logo: SVG, left-aligned (`Clark-1.svg`)
- Links: text-only, Neue Haas Regular, 14px, right-aligned
- Active state: Bold weight, black
- Mobile: hamburger → full-screen overlay menu
- Keyboard: full Tab support, active page indicated with `aria-current="page"`

## Buttons
```
Primary:
  background: #000000
  color: #FFFFFF
  padding: 12px 24px
  font: Neue Haas Regular 14px
  hover: background #333
  focus: 2px solid #000, 2px offset

Secondary:
  background: #FFFFFF
  color: #000000
  border: 1.5px solid #000000
  padding: 11px 23px (accounts for border)
  hover: background #F5F7FA
  focus: 2px solid #000, 2px offset
```

## Cards (Project Thumbnails)
- Background: `#F5F7FA`
- Border: `1px solid #E1E5EB`
- No box-shadow
- Image: 16:9 or 7:4 ratio, object-fit cover
- Title: Neue Haas Bold 14px, below image
- Hover: subtle scale (1.02) or border color change

## Contact Form
- Fields: Name, Email, Message (all required)
- Labels: above inputs, never placeholder-only
- Input border: `#E1E5EB` default → `#000` focus
- Error: red `#D0021B` inline message, `aria-describedby` linked
- Success: green `#1A7F4B` confirmation, `role="status"`
- Email protection: build as JS-assembled string, never plain text in HTML
  ```js
  const parts = ['charlieclark', '@', 'gmail', '.com'];
  // assembled only on user interaction (click/focus)
  ```

## Icons
- Library: Material Icons Outlined (Google Fonts)
- Load: `<link href="https://fonts.googleapis.com/icon?family=Material+Icons+Outlined">`
- Usage: always paired with visible text or `aria-label`
- Size: 20px (inline UI), 24px (standalone)
- Color: inherit from parent text color
