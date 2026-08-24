#!/usr/bin/env python3
"""
Convert a Bravura OTF font to an SVG font file for use with bravura2svg.xsl.

The SVG font format embeds glyph path data as <glyph> elements, which the
XSLT stylesheet can then transform into individual per-glyph SVG files.

Requires: fonttools, lxml
Usage: python3 otf2svgfont.py <input.otf> <output.svg>
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from lxml import etree

SVG_NS = 'http://www.w3.org/2000/svg'
SVG_DOCTYPE = (
    '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"'
    ' "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
)


def _is_valid_xml_char(cp):
    """Return True if codepoint cp is a legal XML 1.0 character."""
    return (cp in (0x9, 0xA, 0xD)
            or 0x20 <= cp <= 0xD7FF
            or 0xE000 <= cp <= 0xFFFD
            or 0x10000 <= cp <= 0x10FFFF)


def otf_to_svgfont(otf_path, output_path):
    font = TTFont(otf_path)
    glyph_set = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font['head'].unitsPerEm

    root = etree.Element(f'{{{SVG_NS}}}svg', nsmap={None: SVG_NS})
    defs = etree.SubElement(root, f'{{{SVG_NS}}}defs')
    font_el = etree.SubElement(defs, f'{{{SVG_NS}}}font',
                               {'id': 'Bravura', 'horiz-adv-x': str(upm)})
    etree.SubElement(font_el, f'{{{SVG_NS}}}font-face',
                     {'font-family': 'Bravura', 'units-per-em': str(upm)})

    for cp, glyph_name in sorted(cmap.items()):
        if not _is_valid_xml_char(cp):
            continue
        if glyph_name not in glyph_set:
            continue
        pen = SVGPathPen(glyph_set)
        glyph_set[glyph_name].draw(pen)
        d = pen.getCommands()
        adv = font['hmtx'].metrics.get(glyph_name, (upm, 0))[0]
        attribs = {
            'glyph-name': f'uni{cp:04X}',
            'unicode': chr(cp),
            'horiz-adv-x': str(adv),
        }
        if d:
            attribs['d'] = d
        etree.SubElement(font_el, f'{{{SVG_NS}}}glyph', attribs)

    tree = etree.ElementTree(root)
    with open(output_path, 'wb') as f:
        tree.write(f, xml_declaration=True, encoding='UTF-8',
                   pretty_print=True, doctype=SVG_DOCTYPE)

    print(f"SVG font written to {output_path}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.otf> <output.svg>", file=sys.stderr)
        sys.exit(1)
    otf_to_svgfont(sys.argv[1], sys.argv[2])
