package com.aerhard.otf2png;

import java.awt.*;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.image.BufferedImage;

public class ImageExtractor {

    private boolean verbose;
    private OutlineTransformer outlineTransformer;
    private Font font;
    private FontRenderContext frc;

    public ImageExtractor(Font font, FontRenderContext frc, boolean verbose) {
        this.font = font;
        this.frc = frc;
        this.verbose = verbose;
    }

    public void setOutlineTransformer(OutlineTransformer outlineTransformer) {
        this.outlineTransformer = outlineTransformer;
    }

    public BufferedImage getImage(int codePoint) {
        String characterString = Character.toString((char) codePoint);
        GlyphVector gv = font.createGlyphVector(frc, characterString);
        Shape outline = gv.getOutline();
        Rectangle zero = new Rectangle();
        //there seems to be a problem in Java 11 & 17 with the method in getPixelBounds, which doesn't convert all glyphs, while gv.getVisualBounds() seems to work
        Rectangle bounds = gv.getVisualBounds().getBounds();
        if (bounds.equals(zero) && verbose) {
            System.out.println("WARNING: bounds are empty for " + codePoint + " : " + bounds);
        }
        outline = outlineTransformer.transform(outline, bounds);
        Dimension resultDimension = outlineTransformer.getResultDimension();
        if (verbose) {
            System.out.println(bounds);
        }
        return createBufferedImage(outline, resultDimension);
    }

    private BufferedImage createBufferedImage(Shape outline, Dimension dimension) {

        int height = dimension.height;
        int width = dimension.width;

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

}
