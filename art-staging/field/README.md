# Field Art Staging

Drop reviewed 64 x 96 RGBA frame PNGs here before packing them into runtime strips.

Directory contract:

art-staging/field/<character>/<action>/frame-01.png

Characters currently admitted to this lane:
- ender
- ionia

Actions and frame counts:
- idle: 8
- walk: 6
- talk: 4
- focus: 6
- attack: 8

Packing commands:
- npm run pack:field-art:ender
- npm run pack:field-art:ionia

The packer refuses missing or incorrectly sized frames. It does not resize, invent, or repair artwork.

After packing:
1. npm run verify:field-pack-readiness
2. inspect the strips visually
3. npm run verify:field-pack-readiness:strict
4. only after review, update manifest status
5. npm run test:chapter1-visual
6. npm run test:chapter1-browser
7. regenerate exact-head screenshots

Do not place 28 x 36 candidate sheets in this staging tree as production frames.
