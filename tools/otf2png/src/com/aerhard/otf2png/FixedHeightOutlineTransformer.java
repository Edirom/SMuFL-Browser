package com.aerhard.otf2png;

import java.awt.*;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;

public class FixedHeightOutlineTransformer implements OutlineTransformer {

    private final int glyphHeight;
    private int height;
    private int padding;
    private Rectangle bounds;
    private double offsetY;
    private Rectangle2D fontBounds;
    private double scalingFactor;

    public FixedHeightOutlineTransformer(Rectangle2D fontBounds, int height, int padding) {
        this.padding = padding;
        this.fontBounds = fontBounds;
        this.height = height;
        this.glyphHeight = height - 2 * padding;
        this.scalingFactor = glyphHeight / fontBounds.getHeight();
        this.offsetY = (fontBounds.getY() * scalingFactor);
    }

    @Override
    public Shape transform(Shape outline, Rectangle bounds) {
        this.bounds = bounds;
        AffineTransform at = new AffineTransform();
        at.translate((bounds.x * -1), (offsetY * -1));
        at.scale(scalingFactor, scalingFactor);
        Shape newOutline = at.createTransformedShape(outline);
        Rectangle newBounds = newOutline.getBounds();
        at = new AffineTransform();
        at.translate((newBounds.x * -1) + padding, (newBounds.y * -1) + padding);
        return at.createTransformedShape(newOutline);
    }

    @Override
    public Dimension getResultDimension() {

        // make sure the width 1px at minimum
        int resultImageWidth = Math.max(1, (int) (bounds.width * scalingFactor) + 2 * padding);
        return new Dimension(resultImageWidth, height);

    }
}
