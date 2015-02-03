package com.aerhard.otf2png;

import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.Option;

import java.awt.*;
import java.awt.font.FontRenderContext;
import java.awt.geom.Rectangle2D;
import java.io.File;
import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import javax.imageio.ImageIO;

public class Otf2png {

    private static final String MODE_ORIGINAL = "original";
    private static final String MODE_FIXED = "fixed";
    private static final String MODE_FIT = "fit";

    private File fontFile;
    private File outPath;
    @Option(name = "-regex", usage = "A regular expression to select glyphs by hex code points [default: .*]")
    private String regex = ".*";
    @Option(name = "-padding", usage = "The padding (in pixels) of the glyphs in the generated images [default: 0]")
    private int padding = 0;
    @Option(name = "-fontsize", usage = "The font size (in pixels) [default: 1000]")
    private float fontSize = 1000;
    @Option(name = "-height", usage = "The height of the result image (in pixels); only relevant in \"fit\" and \"fixed\" mode. If not set or 0, the glyph images' heights equal the glyphs' bounding box heights")
    private int height = 0;
    @Option(name = "-width", usage = "The width of the result image (in pixels); only relevant in \"fit\" mode")
    private int width = 0;
    @Option(name = "-mode", usage = "Specifies the scaling mode. \"original\" outputs glyphs whose dimensions are solely based on the chosen font size; the result images' size can be increased additionally by providing a \"padding\" parameter; depending on the glyph's original height, the heights of the output images may vary. Images created in \"fit\" mode all have the same size; the depicted glyphs maximally fill the dimensions specified with the \"width\" and \"height\" parameters minus padding; in this mode, scaling may vary between glyphs. Images created in \"fixed\" mode all have the same height specified with the \"height\" parameter; the same scaling factor is applied to all glyphs; widths may vary between images.")
    private String mode = MODE_ORIGINAL;
    @Option(name = "-verbose", usage = "Extra status messages [default: false]")
    private boolean verbose = false;
    private Pattern pattern = null;
    private Font font = null;
    private ImageExtractor imageExtractor;

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
        o2p.extractGlyphs();
    }

    @Option(name = "-font", usage = "The path of the font file [required]", required = true)
    public void setFontFile(File fontFile) {
        if (fontFile.exists()) this.fontFile = fontFile;
    }

    @Option(name = "-out", usage = "The output path [required]", required = true)
    public void setOutPath(File outPath) {
        if (outPath.exists() || outPath.mkdir()) this.outPath = outPath;
    }

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
            fail("Could not compile regular expression \"" + regex + "\".");
        }
        FontRenderContext frc = new FontRenderContext(null, true, true);
        createFont();

        //TODO add other parameters
        System.out.println("Font file: " + fontFile.toString());
        System.out.println("Output folder: " + outPath.toString());
        System.out.println("Regex: " + regex);
        System.out.println("Padding: " + padding);
        System.out.println("Font size: " + fontSize);
        System.out.print("Image sizing mode: ");

        OutlineTransformer outlineTransformer;
        if (MODE_FIT.equals(mode)) {
            if (width == 0 || height == 0) {
                fail("Width and height parameters must be specified and > 0 in \"fit\" mode.");
            }
            outlineTransformer = new FitToBoundsOutlineTransformer(width, height, padding);
            System.out.println(MODE_FIT);
            System.out.println("Height: " + height);
            System.out.println("Width: " + width);
        } else if (MODE_FIXED.equals(mode)) {
            if (height == 0) {
                fail("height parameters must be specified and > 0 in \"fixed\" mode.");
            }

//                    Canvas c = new Canvas();
//        FontMetrics fm = c.getFontMetrics(font);
//            Rectangle fontBounds = fm.getMaxCharBounds(c.getGraphics());

            Rectangle2D fontBounds = font.getMaxCharBounds(frc);

            outlineTransformer = new FixedHeightOutlineTransformer(fontBounds, height, padding);
            System.out.println(MODE_FIXED);
            System.out.println("Height: " + height);
        } else  {
            outlineTransformer = new OriginalHeightOutlineTransformer(padding);
            System.out.println(MODE_ORIGINAL);
        }
        imageExtractor = new ImageExtractor(font, frc, verbose);
        imageExtractor.setOutlineTransformer(outlineTransformer);
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
                            ImageIO.write(imageExtractor.getImage(c), "png", new File(outPath, hexCodePoint + ".png"));
                            processedCharCount++;
                        }
                    }
                }
            } catch (IOException e) {
                fail("Error writing image file. " + e.toString());
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
}
