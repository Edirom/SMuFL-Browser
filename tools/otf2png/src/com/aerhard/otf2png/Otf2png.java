package com.aerhard.otf2png;

import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.Option;

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
import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import javax.imageio.ImageIO;

public class Otf2png {

    private File fontFile;
    private File outPath;

    @Option(name = "-font", usage = "The path of the font file [required]", required = true)
    public void setFontFile(File fontFile) {
        if (fontFile.exists()) this.fontFile = fontFile;
    }

    @Option(name = "-out", usage = "The output path [required]", required = true)
    public void setOutPath(File outPath) {
        if (outPath.exists() || outPath.mkdir()) this.outPath = outPath;
    }

    @Option(name = "-regex", usage = "A regular expression to select glyphs by hex code points [default: .*]")
    private String regex = ".*";

    @Option(name = "-padding", usage = "The padding (in pixels) of the glyphs in the generated images [default: 0]")
    private int padding = 0;

    @Option(name = "-fontsize", usage = "The font size (in pixels) [default: 1000]")
    private float fontSize = 1000;

    @Option(name = "-verbose", usage = "Extra status messages [default: false]")
    private boolean verbose = false;

    private Pattern pattern = null;
    private Font font = null;
    private FontRenderContext frc;

    public void init() {
        if (fontFile == null) {
            fail("Could not find font file.");
        }
        if (outPath == null) {
            fail("Could not create output directory.");
        }
        try {
            pattern = Pattern.compile(regex);
        } catch (PatternSyntaxException e) {
            fail("Could not create output directory.");
        }
        frc = new FontRenderContext(null, true, true);
        System.out.println("Font file: " + fontFile.toString());
        System.out.println("Output folder: " + outPath.toString());
        System.out.println("Regex: " + regex);
        System.out.println("Padding: " + padding);
        System.out.println("Font size: " + fontSize);
    }

    private void fail(String msg) {
        System.out.println(msg);
        System.exit(-1);
    }

    public void extractGlyphs() {
        int processedCharCount = 0;
        if (font != null) {
            System.out.println("Processing...");
            try {
                for (int c = 0; c < 65536; c++) {
                    if (font.canDisplay(c)) {
                        String hexCodePoint = String.format("%X", c);
                        Matcher matcher = pattern.matcher(hexCodePoint);
                        if (matcher.matches()) {
                            if (verbose) {
                                System.out.println(c + " - " + hexCodePoint);
                            }
                            ImageIO.write(getImage(c), "png", new File(outPath, hexCodePoint + ".png"));
                            processedCharCount++;
                        }
                    }
                }
            } catch (IOException e) {
                fail("Error writing image file. "+ e.toString());
            }
            System.out.println("Done. Processed glyphs: " + processedCharCount);
        }
    }

    public void createFont() {
        try {
            font = Font.createFont(Font.TRUETYPE_FONT, fontFile);
            font = font.deriveFont(fontSize);
            System.out.println("Font \"" + font.getName() + "\" loaded.");
        } catch (FontFormatException e) {
            fail("Error processing font. " + e.toString());
        } catch (IOException e) {
            fail("Error processing font. " + e.toString());
        }
    }

    public BufferedImage getImage(int codePoint) {

        GlyphVector gv = font.createGlyphVector(frc, Character.toString((char) codePoint));
        Rectangle bounds = gv.getPixelBounds(frc, 0, 0);

        AffineTransform at = new AffineTransform();
        at.translate(bounds.x * -1 + padding, bounds.y * -1
                + padding);
        Shape outline = gv.getOutline();
        outline = at.createTransformedShape(outline);

        if (verbose) {
            System.out.println(bounds);
        }

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

    public static void main(String[] args) throws IOException,
            FontFormatException {

        Otf2png o2p = new Otf2png();
        CmdLineParser parser = new CmdLineParser(o2p);
        try {
            parser.parseArgument(args);
        } catch (CmdLineException e) {
            System.err.println(e.getMessage());
            System.err.println("java -jar otf2png.jar [options...]");
            parser.printUsage(System.err);
            System.exit(-1);
        }

        o2p.init();
        o2p.createFont();
        o2p.extractGlyphs();

//         -font C:/eXist-db/webapp/ahlsen/smufl-browser/tmp/otf/BravuraText.otf -out C:/eXist-db/webapp/ahlsen/smufl-browser/tmp/png-glyphs -regex E.* -padding 0 -fontsize 1000
    }
}
