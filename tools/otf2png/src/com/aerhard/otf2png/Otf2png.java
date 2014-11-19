package com.aerhard.otf2png;

import java.awt.Color;
import java.awt.Font;
import java.awt.FontFormatException;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.Shape;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.imageio.ImageIO;

public class Otf2png {

    private Pattern pattern;
    private int padding;
    private float fontSize;
    private Font font = null;
    private FontRenderContext frc;

    public Otf2png() {

    }

    public Font createFont(File fontPath) throws FontFormatException,
            IOException {
        Font font = null;
        font = Font.createFont(Font.TRUETYPE_FONT, fontPath);
        font = font.deriveFont(fontSize);
        System.out.println("Font \"" + font.getName() + "\" loaded.");
        return font;
    }

    public BufferedImage getImage(String text) {

        GlyphVector gv = font.createGlyphVector(frc, text);
        Rectangle bounds;
//        bounds = gv.getVisualBounds().getBounds();
        bounds = gv.getPixelBounds(frc, 0, 0);
        
        AffineTransform at = new AffineTransform();
        at.translate(bounds.x * -1 + padding, bounds.y * -1
                + padding);
        Shape outline = gv.getOutline();
        outline = at.createTransformedShape(outline);

//        System.out.println(bounds);
        
        // ensure each dimension is 1px at minimum
        int height = Math.max(1, bounds.height + 2 * padding);
        int width = Math.max(1, bounds.width + 2 * padding);
        BufferedImage img = new BufferedImage(width, height,
                BufferedImage.TYPE_INT_ARGB);
        Graphics2D g2 = (Graphics2D) img.getGraphics();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(Color.black);
        g2.fill(outline);
        g2.dispose();    
        return img;
    }

    public void extract(File fontPath, File outPath, int padding,
            float fontSize, String regex) throws IOException,
            FontFormatException {

        String text;
        BufferedImage image;
        File outFile;
        String hexCodePoint;

        this.padding = padding;
        this.fontSize = fontSize;

        System.out.println("Font file: " + fontPath.toString());
        System.out.println("Output folder: " + outPath.toString());
        System.out.println("Regex: " + regex);
        System.out.println("Padding: " + padding);
        System.out.println("Font size: " + fontSize);

        pattern = Pattern.compile(regex);

//        BufferedImage img = new BufferedImage(1, 1,
//                BufferedImage.TYPE_INT_ARGB);
//        Graphics2D g2 = (Graphics2D) img.getGraphics();
//        frc = g2.getFontRenderContext();
        
        frc = new FontRenderContext(null, true, true);

        int processedCharCount = 0;

        font = createFont(fontPath);

        if (font != null) {

            System.out.println("Processing...");

            for (int c = 0; c < 65536; c++) {
                if (font.canDisplay(c)) {
                    text = Character.toString((char) c);
                    hexCodePoint = String.format("%X", c);
                    Matcher matcher = pattern.matcher(hexCodePoint);
                    if (matcher.matches()) {
                        processedCharCount++;
                        image = getImage(text);
                        // System.out.println(c + " - " + hexCodePoint);
                        outFile = new File(outPath, hexCodePoint + ".png");
                        ImageIO.write(image, "png", outFile);
                    }
                }
            }

            System.out.println("Done. Processed glyphs: " + processedCharCount);

        }

    };

    public static void main(String[] arguments) throws IOException,
            FontFormatException {

        String fontPath, outPath, regex;
        int padding;
        float fontSize;

        if (arguments.length != 5) {
            throw new IllegalArgumentException(
                    "Required command line arguments:\n\n"
                            + "otf2png [fontfile] [targetfolder] [regex*] [padding*] [fontsize*]\n"
                            + "* = optional\n"
                            + "Example: otf2png BravuraText.otf resources/images E.* 50 1000\n");
        }

        fontPath = arguments[0];
        outPath = arguments[1];
        regex = arguments[2];
        padding = Integer.parseInt(arguments[3]);
        fontSize = Float.parseFloat(arguments[4]);

//         fontPath =
//         "C:/eXist-db/webapp/ahlsen/smufl-browser/tmp/otf/BravuraText.otf";
//         outPath = "C:/eXist-db/webapp/ahlsen/smufl-browser/tmp/png-glyphs";
//         regex = "E.*";
//         padding = 0;
//         fontSize = 1000;

        Otf2png o2p = new Otf2png();

        File fontFile = new File(fontPath);
        File outFile = new File(outPath);

        if (!fontFile.exists()) {
            throw new FileNotFoundException("Could not find font file: "
                    + fontFile.toString());
        }

        else if (!outFile.exists() && !outFile.mkdir()) {
            throw new RuntimeException("Could not create output path: "
                    + outFile.toString());
        } else {
            o2p.extract(fontFile, outFile, padding, fontSize, regex);
        }
    }

}
