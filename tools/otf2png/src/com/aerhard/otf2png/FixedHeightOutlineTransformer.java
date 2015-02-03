package com.aerhard.otf2png;

import java.awt.*;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;

public class FixedHeightOutlineTransformer implements OutlineTransformer {

    private int padding;
    private Rectangle bounds;
    private double offsetY;
    private Rectangle2D fontBounds;

    public FixedHeightOutlineTransformer(Rectangle2D fontBounds, int padding) {
        this.padding = padding;
        this.fontBounds = fontBounds;
        this.offsetY = fontBounds.getY();

//        System.out.println(fontBounds);
    }

    // TODO auto-margin

    // TODO rename padding to margin

    // TODO report if there occur out-of-bounds coordinates

    @Override
    public Shape transform(Shape outline, Rectangle bounds) {
        this.bounds = bounds;
        AffineTransform at = new AffineTransform();
//        at.translate(bounds.x * -1 + padding, bounds.y * -1
//                + padding);

//        System.out.println(bounds.y * -1
//                + padding);

        at.translate(bounds.x * -1 + padding, offsetY * -1
                + padding);

        return at.createTransformedShape(outline);
    }

    //        System.out.println(font.getMaxCharBounds(frc));
//        Canvas c = new Canvas();
//        FontMetrics fm = c.getFontMetrics(font);
//        System.out.println(fm);

    @Override
    public Dimension getResultDimension() {

        // ensure each dimension is 1px at minimum

//        int defaultResultImageHeight = Math.round(offsetY) + 2 * padding;

//        int resultImageHeight = Math.max(defaultResultImageHeight, bounds.height + 2 * padding);

        int resultImageHeight = Math.round((int) fontBounds.getHeight()) + 2 * padding;

        int resultImageWidth = Math.max(1, bounds.width + 2 * padding);
        return new Dimension(resultImageWidth, resultImageHeight);

    }
}
